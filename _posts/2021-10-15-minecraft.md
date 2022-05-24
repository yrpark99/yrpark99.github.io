---
title: "마인크래프트 플러그인 개발 방법"
category: [Java]
toc: true
toc_label: "이 페이지 목차"
---

마인크래프트 용 플러그인 개발 방법을 정리한다.

<br>
아들 녀석이 마인크래프트 게임을 즐기는데 (주로 맵을 제작하고 서버를 만들어서 친구들과 만든 맵을 즐기는 듯), 자기는 커맨드로 맵을 제작하는데 플러그인이라는 것도 있다고 하여, 사실 나는 마인크래프트 게임을 한 번도 해보지 않은 상태였지만 궁금한 마음에 테스트로 마인크래프트 플러그인을 제작해 보기로 하였다. 🤔

<br>
구글링을 해 보니 많은 자료가 있지는 않았고, 있는 자료들도 오래된 내용들이 많아서 (유사하긴 하지만) 여기에 최신 내용으로 간단히 정리해 본다.


## 마인크래프트 서버 실행
1. 마인크래프트에서 멀티 유저로 게임을 하려면 서버 프로그램이 필요한다. 마인크래프트 서버 프로그램에는 여러 가지가 있는데, 보통 아래 서버 프로그램들이 많이 사용되는 것 같다. (사실상 어느 정도 호환됨)
   - [CraftBukkit](https://getbukkit.org/download/craftbukkit)
   - [Spigot](https://getbukkit.org/download/spigot)
   - [Paper](https://papermc.io/downloads)

    사용할 마인크래프트 버전과 일치되는 버전으로 다운받아서, 원하는 디렉토리에 저장한다. (여기서는 마인크래프트 최신 버전 1.17.1에 맞추어서 Spigot 최신 버전인 v1.17.1을 사용하였음)  
1. 다운을 받으면 Java 실행 파일인 jar 파일이 다운받아지는데, console 창에서 아래와 같이 실행시킨다.
   ```shell
   C:\>java -jar <서버_프로그램.jar>
   ```
   > Jar 프로그램을 실행시키는 것이므로 당연히 필요한 JRE가 설치되어 있어야 하는데, 만약 설치되어 있지 않은 상태라면 관련 에러가 출력된다. 나의 경우 Java 16이 필요하다고 에러가 출력되어, JDK 16을 설치한 후 다시 실행시켰다.  
   JDK는 Oracle을 비롯하여 여러 곳에서 다운받을 수 있는데, Oracle은 계정 로그인(무료이긴 하지만)이 필요한 귀찮음이 있다. 대안으로 [Microsft OpenJDK](https://docs.microsoft.com/ko-kr/java/openjdk/download) 사이트에서도 간단히 다운받을 수 있다.

   실행 결과로 "You need to agree to the EULA in order to run the server. Go to eula.txt for more info."와 같은 에러 메시지가 출력되면서 중단된다. (정상적인 상황임)  
   이때 현재 디렉토리에 `eula.txt` 라는 파일이 생기는데, 이 파일에서 아래와 같이 `eula` 값을 <font color=blue>true</font>로 변경시킨 후 (라이선스 동의 의미임) 저장한다.
   ```ini
   eula=true
   ```
   이제 다시 실행시켜 보면 정상적으로 실행되는 것을 확인할 수 있다. (실행하는 `java.exe` 파일이 Windows Defender 방화벽에서 차단되었다는 팝업이 뜨면 액세스 허용을 해 준다)  
   서버 프로그램이 실행된 디렉토리를 확인해 보면 많은 파일과 디렉토리가 생성되어 있는데, 이 중에서 **server.properties** 파일이 설정 파일이고, **plugins** 디렉토리가 플러그인을 위치시키는 곳이다.
1. 더이상 console은 필요하지 않으므로 (GUI로도 동일한 작업을 할 수 있음) 편의상 서버를 구동시킬 server_start.bat 파일을 아래 내용과 같이 작성한다.
   ```shell
   start javaw -jar <서버_프로그램.jar>
    ```
   이제 server_start.bat 파일을 실행시키면 서버 프로그램이 실행되면서 console은 뜨지 않고 GUI만 보이게 된다.
   > 필요시 Java VM에서 사용할 최소 메모리와 최대 메모리를 `-Xms1G -Xmx2G` 옵션 예와 같이 설정할 수 있다.

## 마인크래프트 서버 접속
1. 마인크래프를 실행시킨 후, "멀티플레이" 버튼을 누르고 리스트에 나온 로컬 서버를 선택한 후 "서버 참여" 버튼을 누르면 된다.
1. 마인크래프트 게임 내에서도 명령어를 실행하려면, 서버 프로그램에서 아래와 같이 `op [플레이어명]` 명령으로 해당 플레이어에게 OP 권한을 부여해야 한다.
   ```ini
   op [플레이어명]
   ```
1. 게임 모드에는 adventure, creative, spectator, survival이 있는데, 아래와 같이 `gamemode` 명령으로 설정할 수 있다.
   ```ini
   gamemode [모드]
   ```
1. 외부에서도 내 서버에 접속할 수 있게 하려면 마인크래프트가 사용하는 포트가 방화벽에서 허용되어야 한다. 포트 번호는 서버 프로그램의 `server.properties` 파일에서 **server-port** 값을 보면 되는데, 모든 마인크래프트 서버 프로그램들은 아래와 같이 디폴트로 <font color=green>25565</font> 포트를 사용하는 것 같다.
   ```ini
   server-port=25565
   ```
   방화벽에서 이 포트를 허용하려면, Windows인 경우에는 Windows Defender 방화벽 프로그램(`wf.msc`)에서 왼쪽의 "인바운드 규칙" 탭을 누른 후, 우측의 인바운드 규칙에서 "새 규칙"을 눌러서 TCP 포트로 <font color=green>25565</font> 포트를 추가하면 된다.  
   이후, 아래와 같은 방법을 사용하여 정상적으로 포트가 open 되었는지 확인할 수 있다.
   - [tcping](https://www.elifulkerson.com/projects/tcping.php) 툴 이용 예
     ```shell
     C:\>tcping <내IP주소> 25565
     ```
   - 또는 [You get signal](https://www.yougetsignal.com/tools/open-ports/) 웹페이지에 접속해서 확인할 수 있다.

## 마인크래프트 기본 key
- 이동: **W, A, S, D**
- 인벤토리 확인: **E**
- 명령어창 열기: **/**
- 디버그 정보 출력: **F3**
- 도구 타입 출력: **F3 + H**

## 플러그인 개발 방법
1. 플러그인은 Java로 개발하고 Jar 파일로 만들어져야 하므로, JDK 설치가 필요하다.  
플러그인 개발시에는 JDK 8, 11, 16 버전 등에서 아무거나 사용해도 되는데, 위에서 마인크래프트 서버 프로그램 실행을 위해 이미 JDK를 설치했으므로, 이것을 그대로 사용해도 된다.
1. Java로 코딩해야 하므로 Java 개발 환경을 사용하면 편리한데, 주로 IntelliJ나 Eclipse가 많이 사용되는 것 같고, 원하면 VS Code를 사용해도 된다.  
나는 [IntelliJ IDEA community 에디션](https://www.jetbrains.com/ko-kr/idea/download/)을 사용하였는데, IntelliJ IDEA에는 `Minecraft Development` 플러그인이 있어서 좀 더 편리한 환경을 만들어 주기 때문이다. IntelliJ IDEA를 설치한 후에, `Minecraft Development` 플러그인을 설치한다.
1. IntelliJ IDEA를 실행한 후, Projects에서 "New Project" 버튼을 누른다. **Minecraft**를 선택하고, Project SDK 항목에서 설치한 JDK를 선택하고, 사용할 플러그인 종류를 선택한다. (예: Spigot Plugin)
1. GroupId에 회사나 본인 이름을 적고, ArtifactId에 작성할 플러그인 이름을 적는다. (아래 예에서는 각각 **my**, **test** 이름을 사용하였음)  
빌드 시스템에는 Maven 대신에 <font color=blue>Gradle</font>을 선택한다.  
자동으로 플러그인 이름과 main class 이름이 나온다.  
이후 사용할 Minecraft Version을 선택한다. (예: latest인 1.17.1)  
Optional Settings 항목은 적지 않아도 무방하다.
1. Project name에 생성할 디렉토리 이름을 적으면 자동으로 해당 디렉토리가 생성되고, 여기에 자동으로 기본 소스 파일들이 생성된다.
1. 마인크래프트 서버 프로그램마다 API가 다르므로, 설치한 서버 프로그램의 API를 참조해야 한다. 예를 들어 Spigot 서버를 사용하는 경우에는 [Spigot 플러그인 API](https://hub.spigotmc.org/javadocs/spigot/) 페이지에서 확인할 수 있다.
1. Test.java 파일을 아래 예와 같이 작성하였다. (한글 인코딩은 UTF-8 사용)
   ```java
   package my.test;

   import org.bukkit.Material;
   import org.bukkit.entity.Player;
   import org.bukkit.event.EventHandler;
   import org.bukkit.event.Listener;
   import org.bukkit.event.block.BlockBreakEvent;
   import org.bukkit.event.block.BlockPlaceEvent;
   import org.bukkit.event.player.PlayerJoinEvent;
   import org.bukkit.plugin.java.JavaPlugin;

   public final class Test extends JavaPlugin implements Listener {
       @Override
       public void onEnable() {
           // Plugin startup logic
           getLogger().info("테스트 플러그인이 활성화되었어요");
           getServer().getPluginManager().registerEvents(this, this);
       }

       @Override
       public void onDisable() {
           // Plugin shutdown logic
       }

       @EventHandler
       public void playerJoinHandler(PlayerJoinEvent e) {
           e.setJoinMessage(e.getPlayer().getName() + " 님이 접속했네요");
       }

       @EventHandler
       public void blockBreakHandler(BlockBreakEvent e) {
           Player p = e.getPlayer();
           p.sendMessage(e.getBlock().getType() + " 블럭을 뿌셨네요");
       }

       @EventHandler
       public void blockPlaceHandler(BlockPlaceEvent e) {
           Player p = e.getPlayer();
           p.sendMessage(e.getBlock().getType() + " 블럭을 놓았네요");
           if (e.getBlock().getType() == Material.STONE) {
               p.sendMessage("특히 이건 돌이네요");
           }
       }
   }
   ```
1. Jar 파일을 빌드하기 위해서, 프로젝트를 선택하고 **Open Module Settings**를 눌러서, **Artifacts** 항목을 선택한 후, `+ (Add)` 버튼을 눌러서 JAR -> Empty를 선택한다.  
Name에는 생성될 Jar 파일의 이름을 적는다.  
우측 **Available Elements** 항목 중에서 main 밑에 있는 **XXX compile output** 항목을 더블 클릭하면, 좌측의 **Output Layout**에 옮겨진다.  
또 플러그인으로 인식되려면 Jar 파일이 <font color=blue>plugin.yml</font> 파일도 포함해야 하므로, **Output Layout**에 있는 `+ (Add Copy of)` 버튼을 눌러서 **Directory Content** 항목을 눌러서, plugin.yml 파일이 있는 디렉토리를 선택한다. (아래 캡쳐 참조)
   <p><img src="/assets/images/minecraft_build.png"></p>
1. 이제부터는 Jar 파일을 빌드하려면 메뉴에서 Build -> Build Artifacts 항목을 누르기만 하면 된다.
1. 빌드된 Jar 파일을 서버 프로그램의 `plugins` 디렉토리에 복사하면 된다. 서버 프로그램을 실행시키면 아래 캡쳐와 같이 작성한 플러그인의 활성화 로그를 확인할 수 있다.
   <p><img src="/assets/images/minecraft_server.png"></p>
1. 참고로 서버 프로그램이 실행 중인 상태에서도 플러그인 Jar 파일을 overwrite 한 후에, `reload` 명령을 실행시키면 모든 플러그인들이 재로딩 된다.

## 플러그인에 커맨드 추가 예
1. 추가로 플러그인에 커맨드를 추가해 보았다. (예로 **test** 명령)  
`plugin.yml` 파일에 아래 형식으로 명령을 추가한다. (아래에서 description, usage, aliases는 생략 가능)
   ```yml
   commands:
       test:
       description: 명령어 설명
       usage: 명령어 사용법
       aliases: [다른이름1, 다른이름2]
   ```
1. 아래 예와 같이 **TestCommand.java** 파일을 작성한다. (소스 관리 편의상 별도의 파일로 분리하였음)
   ```java
   package my.test;

   import org.bukkit.Material;
   import org.bukkit.command.Command;
   import org.bukkit.command.CommandExecutor;
   import org.bukkit.command.CommandSender;
   import org.bukkit.command.ConsoleCommandSender;
   import org.bukkit.entity.Player;
   import org.bukkit.inventory.ItemStack;

   public class TestCommand implements CommandExecutor {
       @Override
       public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
           if(sender instanceof Player) {
               Player player = (Player)sender;
               player.sendMessage("테스트 명령어를 실행했어요");
               ItemStack irons = new ItemStack(Material.IRON_INGOT);
               ItemStack golds = new ItemStack(Material.GOLD_INGOT);
               ItemStack diamonds = new ItemStack(Material.DIAMOND);
               irons.setAmount(10);
               golds.setAmount(20);
               diamonds.setAmount(30);
               player.getInventory().addItem(irons, golds, diamonds);
               return true;
           } else if(sender instanceof ConsoleCommandSender) {
               sender.sendMessage("콘솔에서는 이 명령어를 실행할 수 없어요");
               return false;
           }
           return false;
       }
   }
   ```
   즉, 플레이어가 **test** 명령을 실행하면 해당 플레이어의 인벤토리에 iron, gold, diamond를 각각 10개, 20개, 30개씩 넣어준다.
1. Test.java 파일에 있는 Main 클래스의 onEnable() 함수에 아래 내용을 추가한다.
   ```java
   @Override
   public void onEnable() {
       getCommand("test").setExecutor(new TestCommand());
   }
   ```
1. Jar 파일 빌드 후에 **plugin** 디렉토리로 복사 및 reload를 하면, 이제 마인크래프트에서 **test** 명령을 실행할 때마다 인벤토리에 위 아이템들이 추가되는 것을 확인할 수 있다. (위의 예에서는 명령어로 파라미터를 받지 않았는데, 원하면 onCommand() 함수에서 **args[]** 변수로 뽑아서 처리할 수 있음)

## 결론
마인크래프트 플러그인을 이용하면 쉽고 강력하게 입맛에 맞게 마인크래프트 서버를 구축할 수 있다. 본 글에서는 Windows에서의 예를 들었지만, Linux에서도 동일하게 구현할 수 있고, GCP 등을 이용해 상시 마인크래프트 서버를 구축할 수도 있겠다.
