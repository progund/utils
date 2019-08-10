import java.io.ByteArrayInputStream;
import java.io.Console;
import java.util.List;
import jdk.jshell.*;
import jdk.jshell.Snippet.Status;
import java.nio.*;
import java.nio.file.*;
import java.util.stream.Collectors;

public class MethodEval {
  public static void main(String[] args) {
    int exit = 0;
    try (JShell js = JShell.create()) {
      String method = read(args[0]);
      System.out.println(method);
      
      System.out.println("Evaluating method..");
      List<SnippetEvent> events = js.eval(method);
      if (results(events)) {
        System.out.println("OK");
      } else {
        System.err.println("Not OK");
        exit = 1;
        System.err.println(events);
      }
      System.out.println("Evaluating method call");
      events = js.eval(read("main.java"));
      if (results(events)) {
        System.out.println("OK.");
        if (events.size() == 1 && "30".equals(events.get(0).value())) {
          System.out.println("Evaluated to 30. OK");
        } else {
          System.err.println("Evaluation failed: Got " +
                             events.get(0).value() +
                             " Expected: 30");
        }
      } else {
        System.err.println("Not OK");        
      }
    } catch (Exception e) {
      System.err.println("Error: " + e.getMessage());
    }
  }
  static boolean results(List<SnippetEvent> events) {
    System.out.println(events.size() + " events generated.");
    for (SnippetEvent e : events) {
      StringBuilder sb = new StringBuilder();
      if (e.causeSnippet() == null) {
        switch (e.status()) {
        case VALID:
          sb.append("Successful ");
          break;
        case REJECTED:
          sb.append("Failed ");
          return false;
        }
      } else {
        System.err.println("e.causeSnippet() returned null");
        return false;
      }
    }
    return true;
  }
  static String read(String file) throws Exception {
    return Files.readAllLines(Paths.get(file))
      .stream()
      .collect(Collectors.joining("\n"));
  }
}
