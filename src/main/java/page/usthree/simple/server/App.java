package page.usthree.simple.server;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.logging.Level;
import java.util.logging.Logger;
import static spark.Spark.after;
import static spark.Spark.get;
import static spark.Spark.port;
import static spark.Spark.staticFiles;

public class App {

    private static byte[] content;

    static {
        try {
            var path = "public/greet.html";
            var packagedContent = ClassLoader.getSystemClassLoader().getResource(path);
            if (packagedContent == null) {
                content = Files.readAllBytes(Path.of("/public/greet.html"));
            } else {
                content = ClassLoader.getSystemClassLoader().getResourceAsStream(path).readAllBytes();
            }
        } catch (IOException ex) {
            Logger.getLogger(App.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    public static void main(String[] args) {
        port(8080);
        staticFiles.location("/public");
        get("/*", (req, res) -> {
            res.type("text/html");
            return content;
        });
        after((req, res) -> {
            res.header("sugar", System.getProperty("java.vm.name"));
            res.header("repo", System.getProperty("https://github.com/prodriguezdefino/simple-native-server"));
        });
    }
}
