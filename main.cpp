#include <QCoreApplication>
#include <sqlite3.h>

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);
    sqlite3 *db;
    sqlite3_open(":memory:", &db);
    sqlite3_close(db);
    return 0;
}