/*
 * C4-модель системы сети ПВЗ: C1 (контекст) и C2 (контейнеры).
 * Версия 1.0, 15.10.2026
 * Открыть: https://playground.structurizr.com/ (вставить файл целиком)
 */
workspace "Сеть ПВЗ" {

    model {
        # Люди
        recipient = person "Получатель" "Забирает заказ в ПВЗ"
        operator = person "Оператор ПВЗ" "Принимает рейсы и выдаёт заказы"
        shiftLead = person "Старший смены" "Разбирает спорные случаи, закрывает смену"
        finance = person "Финансы и франчайзи" "Проверяют итоги смен и расхождения"

        # Внешние системы
        marketplace = softwareSystem "Маркетплейсы" "Передают заказы, получают статусы выдачи" "External"
        bank = softwareSystem "Банк" "Проводит оплату на терминале" "External"
        erp = softwareSystem "ERP" "Финансовый учёт компании" "External"
        sms = softwareSystem "SMS-шлюз" "Отправляет SMS с кодом" "External"

        # Наша система
        pvz = softwareSystem "Система сети ПВЗ" "Приёмка, хранение, выдача и сверка заказов" {
            arm = container "АРМ оператора" "Экран приёмки и выдачи. Без связи хранит события и отправляет их позже" "PWA, IndexedDB"
            issue = container "Сервис выдачи" "Проверяет получателя и оплату, фиксирует выдачу без дублей" "Java"
            issueDb = container "БД выдачи" "Заказы к выдаче, коды, события выдачи" "PostgreSQL" "Database"
            payment = container "Адаптер оплаты" "Запускает оплату в банке и узнаёт её статус по ID" "Java"
            intake = container "Сервис приёмки" "Приём рейсов, ячейки, сроки хранения" "Java"
            intakeDb = container "БД приёмки" "Рейсы, ячейки, точки" "PostgreSQL" "Database"
            partners = container "Шлюз партнёров" "Принимает заказы от маркетплейсов, отправляет им статусы" "Java"
            notify = container "Сервис уведомлений" "Отправляет получателю SMS с кодом" "Java"
            recon = container "Сервис сверки" "Собирает реестр смены и расхождения, выгружает в ERP" "Java, веб-интерфейс"
            reconDb = container "БД сверки" "Реестры смен и расхождения" "PostgreSQL" "Database"
            broker = container "Брокер событий" "Передаёт события между сервисами" "Kafka" "Queue"
        }

        # Связи C1
        operator -> pvz "Принимает и выдаёт заказы"
        shiftLead -> pvz "Разбирает спорные случаи"
        finance -> pvz "Смотрит итоги смен"
        marketplace -> pvz "Передаёт заказы"
        pvz -> marketplace "Отправляет статусы выдачи"
        pvz -> bank "Запрашивает оплату"
        pvz -> erp "Передаёт итоги смены"
        pvz -> sms "Отправляет код получения"
        sms -> recipient "Присылает SMS с кодом"

        # Связи C2
        operator -> arm "Принимает и выдаёт заказы"
        shiftLead -> arm "Разбирает спорные случаи, закрывает смену"
        finance -> recon "Смотрит реестры и расхождения"

        arm -> issue "Команды выдачи" "HTTPS, синхронно"
        arm -> intake "Приёмка рейса, поиск ячейки" "HTTPS, синхронно"

        issue -> issueDb "Читает и пишет" "SQL"
        issue -> payment "Запрос оплаты и её статуса" "HTTPS, синхронно"
        issue -> broker "Публикует «Заказ выдан», читает «Заказ размещён»" "Kafka, асинхронно" "Async"
        payment -> bank "Оплата, статус по ID" "HTTPS, синхронно"

        intake -> intakeDb "Читает и пишет" "SQL"
        intake -> broker "Публикует «Заказ размещён», читает «Заказ создан»" "Kafka, асинхронно" "Async"

        marketplace -> partners "Передаёт заказы" "HTTPS, синхронно"
        partners -> marketplace "Отправляет статусы выдачи" "HTTPS, повтор до подтверждения"
        partners -> broker "Публикует «Заказ создан», читает «Заказ выдан»" "Kafka, асинхронно" "Async"

        notify -> broker "Читает «Заказ размещён»" "Kafka, асинхронно" "Async"
        notify -> sms "Отправляет SMS с кодом" "HTTPS"

        recon -> broker "Читает события выдачи" "Kafka, асинхронно" "Async"
        recon -> reconDb "Читает и пишет" "SQL"
        recon -> erp "Выгружает реестр смены" "HTTPS, раз в смену"
    }

    views {
        systemContext pvz "C1" {
            title "C1 · Контекст · Система сети ПВЗ · v1.0"
            include *
            include recipient
            autoLayout lr
        }

        container pvz "C2" {
            title "C2 · Контейнеры · Система сети ПВЗ · v1.0"
            include *
            autoLayout lr
        }

        styles {
            element "Element" {
                fontSize 22
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Database" {
                shape Cylinder
            }
            element "Queue" {
                shape Pipe
            }
            relationship "Relationship" {
                fontSize 20
                style solid
            }
            relationship "Async" {
                style dashed
            }
        }
    }
}
