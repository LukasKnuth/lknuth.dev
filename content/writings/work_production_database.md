---
title: "Survive on the production Database"
date: 2024-12-09T22:15:56+01:00
---

TODO new title?

Eventually, you'll connect to the production instance of your relational database.
Perhaps just to check something.
Or to make a _small_ change manually.

## What to look out for

SQL notation for destructive operations is unfortunate.
To delete a specific row from your `users` table, you'll have to type `DELETE FROM users` first.
A fat-fingered enter tap and all your users are gone.

The same goes for updating a single user, you'll have to type `UPDATE users SET name = 'Jeff'` before you can put your `WHERE` clause.
Suddenly, everyone's Jeff.
That's no good at all!

Some might say "but you're missing a semicolon at the end there!".
Well, often enough you'll re-run previously run commands with the Up-Arrow.
Pick the wrong one (perhaps a very similar one) and press Enter too quickly.

Another classic is when picking from the list of recent commands to edit one.
Only to again, press Enter too early.

Lastly, ever get surprised when you run any of the above statements and see the database respond with "1208 records updated", where you would expect 2?
Wrong `WHERE` clauses happen.

Luckily, there is a cure here.

## Transactions

When connecting to the database, just get in the habit of running `BEGIN;` right off of the bat.
This starts a new [transaction](https://www.postgresql.org/docs/17/sql-begin.html).
Any changes done within this transaction can be undone with a simple `ROLLBACK;`

```sql
BEGIN;
SELECT * FROM users;
UPDATE users SET name = 'Jeff';
-- Oh damn
ROLLBACK;
```

The nice thing about transactions is the [ACID](https://en.wikipedia.org/wiki/ACID) guarantees us **I**solation.
That means within your transaction you can make changes, check if everything looks okay and _then_ commit them when you're happy.
Nobody else will see the in-progress changes until you run `COMMIT;`

```sql
BEGIN;
SELECT * FROM users; -- find the user
UPDATE users SET name = 'Jeff' WHERE id = "abcd-1234";
SELECT id, name FROM users WHERE id = "abcd-1234"; -- verify
COMMIT; -- if everything looks good
```

## Savepoints

Within a transaction, there are certain actions that will auto-cancel the transaction.
Annoyingly, some databases (like Postgres) also treat syntax errors this way.

```sql
BEGIN;
UPDATE users SET name = 'Jeff' WHERE id = "abcd-1234";
SELECT name, login_method FROM users GROUP login_method; -- darn
-- The transaction is cancelled now, COMMIT won't work
ROLLBACK;
-- But now the UPDATE is rolled back as well!
```

But there is a solution again.
If _part_ of your work is done, but you want to keep the transaction running, you can add a [savepoint](https://www.postgresql.org/docs/17/sql-savepoint.html).
This allows you to roll back to the _savepoint_ keeping anything that you wrote before.

```sql
BEGIN;
UPDATE users SET name = 'Jeff' WHERE id = "abcd-1234";
SAVEPOINT jeff;
SELECT name, login_method FROM users GROUP login_method; -- darn
-- The transaction is cancelled now, COMMIT won't work
ROLLBACK TO SAVEPOINT jeff;
-- Our update is still there and we can continue using the transaction
-- Eventually...
COMMIT;
```

Savepoints must have a name, but you can override a previous one by reusing its name.
