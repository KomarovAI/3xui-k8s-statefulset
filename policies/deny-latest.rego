package main

deny[msg] {
  input.kind == "StatefulSet"
  container := input.spec.template.spec.containers[_]
  endswith(container.image, ":latest")
  msg = sprintf("Контейнер '%s' использует :latest тег — запрещено!", [container.name])
}
