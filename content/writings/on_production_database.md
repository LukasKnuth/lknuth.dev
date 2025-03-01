---
title: "On the production Database"
date: 2025-02-27T14:15:56+01:00
---

Eventually, you'll connect to the production instance of your relational database.
Perhaps just to check something.
Or to make a _small_ change manually.

<!--more-->

## What to look out for

SQL notation for destructive commands is unfortunate.
To delete a specific row from your `users` table, you'll have to type `DELETE FROM users` first.
A fat-fingered enter tap and all your users are gone.

The same goes for updating a single user, you'll have to type `UPDATE users SET name = 'Jeff'` before you can put your `WHERE` clause.
Suddenly, everyone's Jeff.
That's no good at all!

Some might say "but you're missing a semicolon at the end there!".
That's a lot of hopes to pin on a single character.
Often enough you'll re-run a previous command using the Up-Arrow.
Pick the wrong one (perhaps a very similar one) and press Enter too quickly...

Speaking of the previously run commands, sometimes you want to run a second command that is very similar to the previous one.
So you browse through the list, find the one you want, make the change and press enter.
Shucks, you forgot to remove that on column and now all users where created `now()`.

Lastly, ever get surprised when you run a statement and see the database respond with "1208 records updated" - when you were expecting 2?
Wrong `WHERE` clauses happen.

If only you could undo your command...

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
UPDATE users SET name = 'Jeff' WHERE id = 'abcd-1234';
SELECT id, name FROM users WHERE id = 'abcd-1234'; -- verify
COMMIT; -- if everything looks good
```

## Savepoints

Within a transaction, there are certain actions that will auto-cancel the transaction.
Annoyingly, some databases (like Postgres) also treat syntax errors this way.

```sql
BEGIN;
UPDATE users SET name = 'Jeff' WHERE id = 'abcd-1234';
SELECT name, login_method FROM users GROUP login_method; -- darn
-- The transaction is cancelled now, COMMIT won't work
ROLLBACK;
-- But now the UPDATE is rolled back as well!
```

But there is a solution again.
If _part_ of your work is done, but you want to keep the transaction running, you can add a [savepoint](https://www.postgresql.org/docs/17/sql-savepoint.html).
This allows you to roll back to the _savepoint_ instead of the whole transaction.

```sql
BEGIN;
UPDATE users SET name = 'Jeff' WHERE id = 'abcd-1234';
SAVEPOINT jeff;
SELECT name, login_method FROM users GROUP login_method; -- darn
-- The transaction is cancelled now, COMMIT won't work
ROLLBACK TO SAVEPOINT jeff;
-- Our update is still there and we can continue using the transaction
-- Eventually...
COMMIT;
```

Savepoints must have a name, but you can override a previous one by reusing its name.

## Working with outputs

`psql` (and others?) use `less` to paginate large results from `SELECT` queries.
These can become unreadable if the table has many columns or content in columns is very wide, because long lines are wrapped by default.
You can type `-S` followed by Enter in `less` to instead allow you to scroll horizontally.

To quickly save the output of your last query [to a CSV file](https://www.postgresql.org/docs/devel/app-psql.html#APP-PSQL-OPTION-CSV), run the following commands in `psql`:

```
psql>\pset format csv
psql>\o '/path/to/output.csv'
psql>SELECT * FROM users;
psql>\o
```

The commands, in order, do the following:

1. Set the output format to CSV, with headers. This means any query you run now will output CSV to stdout.
2. Instead of printing query output to stdout, write it to the given file **on the local system**.
3. Any query to get the data.
4. Print query output to stdout again.

This can also be scripted by passing the query and the matching option to `psql`:

```
psql -d database -c 'SELECT * FROM users' --csv > output.csv
psql -d database -f path/to/query.sql --csv > output.csv
```

The first notation is great for simple queries that fit comfortably on a single line.
For more complex queries, you can write the query to a file - which supports breaking it up in to multiple lines - and run it from the file directly.

## Conclusion

To reiterate: Get in the habit of running `BEGIN;` before you make any changes to the database.
You'll always have the option to undo them if you're not happy.
Don't forget to `COMMIT;` when you're happy.
