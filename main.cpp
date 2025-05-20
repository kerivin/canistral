// #include "document_processor.h"
#include <qt6/QtWidgets/QApplication>
#include <qt6/QtWidgets/QMainWindow>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    
    //DocumentProcessor processor("/usr/lib/libreoffice");
    //auto text = processor.extractText("book.odt");
    
    QMainWindow window;
    window.setWindowTitle("Canistral");
    window.show();
    
    return app.exec();
}