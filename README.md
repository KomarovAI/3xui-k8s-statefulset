## 🛡️ Контейнерные проверки & Best Practices

Docker image проходит следующие mandatory проверки перед публикацией:

- **Hadolint:** Lint Dockerfile (syntax/best practices)
- **Dockle:** Security/best practices for production
- **Dive:** Аудит образа на мусор/размер
- **Container Structure Test (Google):** Проверка обязательного содержимого и ENV
- **Trivy:** Сканирование на CVE
- **DGOSS:** Тест runtime внутри контейнера (процессы, файлы, порты)
- **Push в DockerHub**: только если всё clean!

Кастомные правила: см. [structure-test.yaml](structure-test.yaml), [goss-tests/goss.yaml](goss-tests/goss.yaml).
