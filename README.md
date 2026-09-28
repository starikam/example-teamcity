# Домашнее задание «Teamcity - Викторов Михаил»

Fork: https://github.com/starikam/example-teamcity

## Подготовка

Инфраструктура поднята в Yandex Cloud через Terraform, код - в [infra/terraform](infra/terraform):

| ВМ | Ресурсы | Что внутри |
|---|---|---|
| teamcity-server | 4 CPU / 4 ГБ | Container Optimized Image, `jetbrains/teamcity-server:2026.1.3` |
| teamcity-agent | 2 CPU / 4 ГБ | Container Optimized Image, `jetbrains/teamcity-agent:2026.1.3`, `SERVER_URL=http://10.10.1.10:8111` |
| nexus | 2 CPU / 4 ГБ | AlmaLinux 8, Nexus 3.14 из playbook [infra/infrastructure](infra/infrastructure) |

Были большие проблемы с доступом к Docker Hub и Maven Central, что пришлось поправить:


- образы берутся через зеркало `mirror.gcr.io`
- Системный Python 3.6 слишком стар для современного ansible-core - cloud-init
  ставит `python3.11`.
- в `settings.xml` добавлено зеркало на `maven-public` в Nexus по внутреннему адресу, все зависимости идут через него.
- `download.jetbrains.com` также был недоступен.

## Основная часть

### Задачи

1–3. Проект создан из fork, первая сборка упала из-за недоступного Maven Central:

```
[Step 1/1] Using predefined Maven user settings: settings.xml
[Step 1/1] [INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0
[Step 1/1] [INFO] BUILD SUCCESS
```

4. Два шага Maven с условиями по `teamcity.build.branch`:
`clean deploy`, если ветка `master`, иначе `clean test`.

5. `settings.xml` с кредами Nexus загружен в Maven Settings проекта.

6. В `pom.xml` - адрес Nexus: `http://111.88.254.144:8081/repository/maven-releases`.

7. Сборка `master` выложила артефакт в Nexus:

```
[Step 1/2] [INFO] Uploaded to nexus: http://111.88.254.144:8081/repository/maven-releases/org/netology/plaindoll/0.0.2/plaindoll-0.0.2.jar
[Step 1/2] [INFO] BUILD SUCCESS
[Step 2/2] Build step test (not master) (Maven) is skipped because of unfulfilled condition: "teamcity.build.branch does not equal master"
```

8. Build configuration перенесена в репозиторий (Versioned Settings, формат Kotlin) -
каталог [.teamcity](.teamcity), коммит `a894aa6` сделал TeamCity.

9–12. Ветка `feature/add_reply`: метод `Welcomer.sayReply()` возвращает
«A hunter must hunt, and this night is far from over.», тест `welcomerSaysReplyWithHunter`
проверяет слово `hunter`. Версия изменена на `0.0.3`, чтобы в Nexus легла новая версия.

13. Сборка по ветке запустилась сама после push:

```
Triggered by 'Git'
[Step 1/2] Build step deploy (Maven) is skipped because of unfulfilled condition: "teamcity.build.branch equals master"
[Step 2/2] [INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
[Step 2/2] [INFO] BUILD SUCCESS
```

14. `feature/add_reply` влита в `master` через merge `335eedc`.

15. В автосборке `master` после merge артефактов нет (`0` файлов), при этом `0.0.3` ушла в Nexus.

16–17. В конфигурацию добавлено `artifactRules = "target/*.jar => target"`, повторная сборка `master`
прошла, в артефактах `target/plaindoll-0.0.3.jar` и `target/original-plaindoll-0.0.3.jar`.

18. Изменение Artifact paths TeamCity сам закоммитил в репозиторий (`3ce43a4`), статус Versioned Settings:
*successfully committed*. В [.teamcity/settings.kts](.teamcity/settings.kts) - оба шага с условиями,
`settings.xml`, VCS-триггер и правила артефактов.
