# Анализ данных образовательной платформы ITResume
Отдел маркетинга платформы ITResume хочет поменять модель монетизации платформы - внедрить подписку. Для принятия решений отделом маркетинга были выделены основные метрики, которые необходимо посчитать, используя БД платформы ITResume.
Перечень метрик: 

1. Метрика n-day retention: обычный ретеншен 0, 1, 3, 7, 14 и 30 дня - это поможет понять активность пользователей. Считать метрику нужно по когортам: в зависимости от месяца регистрации. Необходимо также выгрузить результаты в Excel и построить график n-day retention.
2. Метрика rolling retention: в сущности, эта метрика более показательна - человек вполне может зайти на платформу не в 7, а в 8 день. Это основная метрика для оценки активности пользователей и удержания. Здесь аналогично - считаем по когортам. Необходимо также выгрузить результаты в Excel и построить график rolling retention.
3. Среднее и медианное число решаемых задач и тестов (за все время) - эта метрика поможет понять, нужно ли ограничивать количество задач и тестов. Например, «10 задач - бесплатно, остальные - по подписке». Необходимо считать не только правильно решенные задачи и пройденные до конца тесты, а задачи, которые имеют run/submit, и тесты, которые есть в TestStart.
4. Среднее и медиану, но только по правильно решенным задачам - как вариант, можно ограничивать количество только правильно решенных задач.
5. Среднее и медианное значение по количеству попыток (общее - отдельно, неправильных попыток - отдельно) для решения одной задачи. Это поможет принять решение об ограничении на количество попыток.
6. Сколько монет в среднем списывает пользователь за весь срок жизни? Сколько монет ему начисляется? Какая дельта между этими двумя метриками? Это позволит понять, сколько вообще потенциально пользователи «вырабатывают» денег на платформе. Зная курс 1 коина к рублю, можно легко конвертировать потраченные монеты в реальные деньги - это даст какой-то ориентир при формировании стоимости подписки.
7. Среднее значение - это хорошо, но распределение итогового баланса также очень интересно, потому что там могут возникать очень неожиданные результаты. Как минимум, оценить стоит. Необходимо посчитать перцентили с шагом в 0.1. То есть считаем баланс каждого пользователя, а потом смотрим на перцентили.
8. Количество купленных подсказок и решений. Интересно, сколько их купили в сумме (отдельно - подсказки, отдельно - решения), а также в среднем на 1 пользователя.
9. Количество открытых задач и тестов. Интересно, сколько в сумме купили закрытые задачи и тесты (отдельно - задачи, отдельно - тесты), а также в среднем на 1 пользователя. Также стоит посмотреть, сколько людей купили хотя бы 1 задачу/тест, а сколько решали только бесплатные (но при этом решали хотя бы 1 задачу/тест).
10. Как связана дата захода на платформу и активность пользователя. Под активностью имеется ввиду попытка решить задачу/тест. Необходимо посмотреть - какой % заходов не сопровождается активностью.
11. Необходимо посчитать MAU/DAU/WAU - это позволит в целом понять ситуацию по активности. Считаем просто на основании захода на платформу.
12. Распределение активности по дням. Необходимо также выгрузить результаты в Excel и построить график распределения активности по дням.
13. Распределение активности по времени суток. Необходимо также выгрузить результаты в Excel и построить график распределения активности по времени суток.

### Дополнительная информация:
- В расчетах retention необходимо исключить пользователей с id < 94 - это внутренние аккаунты
- В расчетах retention необходимо исключить с company_id = 1 - это студенты крупного университета, они вносят существенный вклад и искажают статистику
- Когорты при расчете retention формируем по месяцам регистрации пользователей и только начиная с 2022 года
- При расчёте количества купленных подсказок, задач, тестов и т.д., необходимо опираться на таблицу Transaction - там есть вся необходимая информация
- У пользователя в таблице Users есть поле company_id. Если оно заполнено - значит пользователь является студентом какой-то компании.
- Информация о компаниях содержится в таблице Company.
- Информация о задачах содержится в таблице Problem.
- Когда человек нажимает Выполнить, делается запись в таблицу CodeRun
- Когда человек нажимает Проверить, делается запись в таблицу CodeSubmit
- Когда человек начинает проходить тест, делается запись в таблицу TestStart
- Когда человек закончил тест полностью (или вышло время), делется запись в таблицу TestResult со всеми его ответами
- Информация о тестах, вопросах и ответах на вопросы можно найти в таблицах Test, TestQuestion, TestAnswer
- в таблице Transaction хранится информация обо всех транзакциях на платформе (это операции с коинами)
- TransactionType - таблица с описанием типа транзакции
- UserEntry - таблица с информацией о заходе людей на платформу
- У одной задачи может быть несколько возможных языков. Информация об этом - в таблице-связке LanguageToProblem. Информация о языках - в таблице Language
## Используемые библиотеки и инстументы
*PostgreSQL*, *Excel*
