---
title: "Android 서비스 AIDL 예제"
category: [Android]
toc: true
toc_label: "이 페이지 목차"
---

Android에서 AIDL을 사용하여 예제 서비스를 구현해 보았다.  
<br>

GitHub에서 관련 예제를 몇 개 찾을 수 있었지만, 모두 안드로이드 스튜디오에서 빌드하면 잘 되었으나, AOSP 환경에서 빌드하면 실패하였다. 그래서 직접 안드로이드 스튜디오와 AOSP에서 모두 빌드가 잘 되도록 구성해 보았고 기록을 남긴다.

## Android service
Android service는 Activity, Broadcast, Contents Provider와 함께 안드로이드 4대 컴포넌트 중 하나로 자세한 사항은 
[[서비스 정보]](https://developer.android.com/develop/background-work/services?hl=ko) 페이지를 참조한다.

## 서비스 bind 종류
- `Unbounded service`
  - App 컴포넌트가 **startService()**를 호출하면, 서비스는 실행되고(started) 그 서비스를 실행한 컴포넌트가 종료되어도 할 일을 모두 마칠 때까지 서비스는 종료되지 않는다.
  - 따라서 서비스가 할일을 다하여 종료시키고 싶다면, 서비스 내에서 stopSelf()를 호출하여 스스로 종료되도록 하거나, 다른 컴포넌트에서 stopService()를 호출하여 종료시켜야 한다.
  - 액티비티 등의 앱 컴포넌트는 startService()를 호출함으로써 서비스를 실행할 수 있고, 이때 어떤 서비스를 실행할지에 대한 정보와 그 외에 서비스에 전달해야할 데이터를 담고 있는 인텐트를 인자로 넘길 수 있다. 그리고 서비스의 **onStartCommand()** 콜백 메소드에서 매개변수로 그 인텐트를 받게 된다.
- `Bounded service`
  - App 컴포넌트가 startService() 메소드 대신에 **bindService()** 메소드를 호출하면 서비스가 시작되고 바인딩된다. (이를 Service Bind 혹은 Bound Service라고 함)
  - 바인드된 서비스는 구성요소가 서비스와 상호작용하고, 요청을 보내고, 결과를 수신하고, 프로세스 간 통신(IPC)을 통해 프로세스 전반에서 이러한 작업을 할 수 있는 클라이언트-서버 인터페이스를 제공한다.
  - 이는 마치 클라이언트-서버와 같이 동작을 하는데 서비스가 서버 역할을 한다. (액티비티는 서비스에게 어떠한 요청을 할 수 있고, 서비스로부터 요청에 대한 결과를 받을 수 있음)
  - 하나의 서비스에 다수의 액티비티 연결이 가능하며, 서비스 바인딩은 연결된 액티비티가 사라지면 서비스도 소멸된다. (즉 백그라운드에서 무한히 실행되지는 않음)
  - 클라이언트가 서비스와의 접속을 마치려면 **unbindService()**를 호출한다.

## 서비스 구현 방법
Service 구현은 다음 3가지 방법 중의 하나로 구현할 수 있다.
- `Binder 클래스 확장`: 공개 메소드에 직접 액세스하는 방법으로, 서비스가 애플리케이션을 위해 단순히 백그라운드에서 작동하는 요소에 그치는 경우 선호된다.
- `Messenger`: 프로세스 간 통신(IPC)을 실행하는 가장 간단한 방법으로 인터페이스가 여러 프로세스에서 작동해야 하는 경우에 선호된다. 메신저는 내부적으로 AIDL을 이용하여 구현되었고, 쉽게 사용할 수 있는 Messenger 클래스를 제공한다. 메신저는 하나의 쓰레드에서 모든 클라이언트들의 요청을 처리하므로 간단한 메시징에는 적합하지만, 여러 클라이언트가 동시에 복잡한 데이터를 처리해야 할 경우에는 적합하지 않다.
- `AIDL`: AIDL 파일을 이용한다. AIDL은 복잡한 IPC 요구 사항을 처리할 수 있는 강력한 도구로, 양방향 통신, 다중 클라이언트 처리, 대량의 데이터 전달이 가능하며, 서비스와 클라이언트 간에 명확한 인터페이스 정의를 제공한다. 특히, 커스텀 객체를 포함한 다양한 데이터 구조를 처리할 수 있어 유연성이 높다.

## 서비스의 생명 주기
각각 unbounded 서비스와 bounded 서비스의 생명 주기는 아래 다이어그램과 같다.  
![](/assets/images/Android_service_lifecycle.drawio.svg)  

## 내 Android 서비스 예제
AIDL을 이용하여 Android bounded 서비스의 server와 client 앱을 아래와 같이 구현하였다.  
서비스가 제공하는 함수는 랜덤 넘버를 얻는 함수와, 콜백 함수를 등록/해제하는 함수이다.  
참고로 전체 소스는 [https://github.com/yrpark99/MyServiceAidlExample.git](https://github.com/yrpark99/MyServiceAidlExample.git) 페이지에서 확인할 수 있다.

### 서비스 server 단 (MyServiceServer)
아래와 같이 **apps/MyServiceServer/app/src/main/aidl/com/my/myserviceserver/IMyRemoteService.aidl** 파일을 작성하였다.

```java
package com.my.myserviceserver;

import com.my.myserviceserver.IMyRemoteServiceCallback;

interface IMyRemoteService {
    int getRandomNumber();
    boolean registerCallback(IMyRemoteServiceCallback callback);
    boolean unregisterCallback(IMyRemoteServiceCallback callback);
}
```

또, **apps/MyServiceServer/app/src/main/aidl/com/my/myserviceserver/IMyRemoteServiceCallback.aidl** 파일을 아래와 같이 작성하였다.
```java
package com.my.myserviceserver;

interface IMyRemoteServiceCallback {
    void onMyServiceStateChanged(int state);
}
```
<br>

이 AIDL 파일은 AOSP에 포함된 `aidl` 툴로 수동으로 Java 파일로 변환할 수는 있으나, 자동으로 빌드되는 방법이 좀 더 좋으므로, 나는 자동으로 빌드되는 방법을 사용하였다. 이를 위해서는 안드로이드 스튜디오와 AOSP 빌드 환경에서 필요한 설정이 다른데, 나는 두 환경 모두 지원하도록 하였다.  
안드로이드 스튜디오를 위해서는 **app/build.gradle.kts** 파일에서 아래와 같이 추가되어야 안드로이드 스튜디오에서 메뉴 File → New → AIDL로 aild 파일을 추가할 수 있다. (이후 빌드하면 자동으로 java 파일이 생성됨)
```gradle
android {
    buildFeatures {
        aidl = true
    }
}
```

또, AOSP 빌드를 위해서 **Android.bp** 파일에 아래 내용을 추가하였다. (이 방법을 알아내느라 고생 좀 했다. 😓)
```json
java_library {
    name: "myserviceserver-aidl",
    srcs: [
        "app/src/main/aidl/com/my/myserviceserver/IMyRemoteServiceCallback.aidl",
        "app/src/main/aidl/com/my/myserviceserver/IMyRemoteService.aidl",
    ],
    aidl: {
        local_include_dirs: ["app/src/main/aidl"],
        export_include_dirs: ["app/src/main/aidl"],
    },
    sdk_version: "current",
}

android_app {
    static_libs: [
        "myserviceserver-aidl",
    ],
}
```
<br>

**AndroidManifest.xml** 파일에서는 **application** 밑에 아래 내용을 추가하여 서비스를 export 시켰다.
```xml
<service
    android:name=".MyRemoteService"
    android:enabled="true"
    android:exported="true">
    <intent-filter>
        <action android:name="MyRemoteService"/>
    </intent-filter>
</service>
```
<br>

이후 **app/src/main/java/com/my/myserviceserver/MyRemoteService.java** 파일을 다음과 같이 구현하였다. (getRandomNumber() 함수 구현, 3초마다 등록된 콜백 함수를 서비스 state(테스트로 1부터 1씩 증가) 값을 넘겨서 호출함)
```java
package com.my.myserviceserver;

import android.app.Service;
import android.content.Intent;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.RemoteCallbackList;
import android.os.RemoteException;
import android.util.Log;

import java.util.Random;

public class MyRemoteService extends Service {
    private final String TAG = "MyServiceServer";
    private final Random mGenerator = new Random();
    private final RemoteCallbackList<IMyRemoteServiceCallback> callbacks = new RemoteCallbackList<>();
    private final Handler handler = new Handler(Looper.getMainLooper());
    private boolean isRunning = false;
    private int state = 1;

    private final Runnable periodicTask = new Runnable() {
        @Override
        public void run() {
            if (isRunning) {
                Log.i(TAG, "Call callback function with state: " + state);
                try {
                    callRegisteredCallback(state);
                } catch (RemoteException e) {
                    Log.e(TAG, "RemoteException", e);
                }
                state++;
                handler.postDelayed(this, 3000);
            }
        }
    };

    public IMyRemoteService.Stub binder = new IMyRemoteService.Stub() {
        @Override
        public int getRandomNumber() {
            int randomNum = mGenerator.nextInt(1000);
            Log.i(TAG, "getRandomNumber() return randomNum: " + randomNum);
            return randomNum;
        }

        @Override
        public boolean registerCallback(IMyRemoteServiceCallback callback) {
            boolean ret = callbacks.register(callback);
            Log.d(TAG, "registerCallback: " + ret);
            isRunning = true;
            handler.post(periodicTask);
            return ret;
        }

        @Override
        public boolean unregisterCallback(IMyRemoteServiceCallback callback) {
            boolean ret = callbacks.unregister(callback);
            Log.d(TAG, "unregisterCallback: " + ret);
            isRunning = false;
            handler.removeCallbacks(periodicTask);
            return ret;
        }
    };

    public void callRegisteredCallback(int state) throws RemoteException {
        Log.d(TAG, "callRegisteredCallback() state:" + state);
        int num = callbacks.beginBroadcast();
        for (int i = 0; i < num; i++) {
            IMyRemoteServiceCallback item = callbacks.getBroadcastItem(i);
            if (item != null) {
                Log.i(TAG, "Call onMyServiceStateChanged() with state: " + state);
                item.onMyServiceStateChanged(state);
            }
        }
        callbacks.finishBroadcast();
    }

    @Override
    public IBinder onBind(Intent intent) {
        Log.i(TAG, "onBind()");
        return binder;
    }
}
```

### 서비스 client 단 (MyServiceClient)
Server 단에서 작성한 **IMyRemoteService.aidl**, **IMyRemoteServiceCallback.aidl** 파일을 복사하였고, **app/build.gradle.kts** 파일과  **Android.bp** 파일도 동일하게 구성하였다.  
**AndroidManifest.xml** 파일에서는 아래 내용을 추가하여 사용할 서비스를 query 할 수 있도록 하였다.
```xml
<queries>
    <package android:name="com.my.myserviceserver"/>
</queries>
```
<br>

이후 **app/src/main/java/com/my/myserviceclient/MainActivity.java** 파일을 다음과 같이 작성하였다.
```java
package com.my.myserviceclient;

import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.os.RemoteException;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.my.myserviceserver.IMyRemoteService;
import com.my.myserviceserver.IMyRemoteServiceCallback;

public class MainActivity extends AppCompatActivity {
    private final String TAG = "MyServiceClient";
    private IMyRemoteService mRemoteService = null;
    private Button btnRandomNumber;
    private TextView tvRandomNumber, tvStateFromCallback;

    /** Callbacks for service binding */
    private final ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName className, IBinder service) {
            Log.i(TAG, "onServiceConnected() Service is bounded");
            mRemoteService = IMyRemoteService.Stub.asInterface(service);
            registerCallback();
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            Log.i(TAG, "onServiceDisconnected() Service is unbounded");
            mRemoteService = null;
        }
    };

    /* Callbacks for service callback */
    private IMyRemoteServiceCallback mCallback = new IMyRemoteServiceCallback.Stub() {
        @Override
        public void onMyServiceStateChanged(int state) {
            Log.i(TAG, "onMyServiceStateChanged() state: " + state);
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    tvStateFromCallback.setText("Callback state: " + String.valueOf(state));
                }
            });
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.i(TAG, "onCreate()");
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        btnRandomNumber = findViewById(R.id.btnRandomNumber);
        tvRandomNumber = findViewById(R.id.tvRandomNumber);
        tvStateFromCallback = findViewById(R.id.tvStateFromCallback);
    }

    @Override
    protected void onStart() {
        Log.i(TAG, "onStart()");
        super.onStart();
        bindToMyRemoteService();
    }

    /* Bind to service: Create Intent with service name defined in server app manifest */
    private void bindToMyRemoteService() {
        Log.i(TAG, "bindToMyRemoteService()");
        Intent intent = new Intent("MyRemoteService");
        intent.setPackage("com.my.myserviceserver");
        bindService(intent, serviceConnection, BIND_AUTO_CREATE);
    }

    @Override
    protected void onResume() {
        super.onResume();
    }

    public void onRandomNumberButtonClick(View view) {
        if (mRemoteService == null) {
            Log.i(TAG, "Service is not bounded yet");
            return;
        }
        try {
            // Call service for a random number
            int randomNum = mRemoteService.getRandomNumber();
            Log.i(TAG, "Got randomNum: " + randomNum);
            tvRandomNumber.setText(String.valueOf(randomNum));
        } catch (RemoteException e) {
            Log.e(TAG, "RemoteException: " + e.getMessage());
        }
    }

    @Override
    protected void onStop() {
        Log.i(TAG, "onStop() Unbind service");
        super.onStop();
        unRegisterCallback();
        unbindService(serviceConnection);
        mRemoteService = null;
    }

    private void registerCallback() {
        if (mRemoteService == null) {
            return;
        }
        try {
            mRemoteService.registerCallback(mCallback);
        } catch (RemoteException e) {
            Log.e(TAG, "RemoteException: " + e.getMessage());
        }
    }

    private void unRegisterCallback() {
        if (mRemoteService == null) {
            return;
        }
        try {
            mRemoteService.unregisterCallback(mCallback);
        } catch (RemoteException e) {
            Log.e(TAG, "RemoteException: " + e.getMessage());
        }
    }
}
```

위 소스는 대략 다음과 같은 작업을 한다.
- 시작시 bindToMyRemoteService() 함수에서 `bindService()`를 호출하여 서비스를 bind 시킨다.
- 서비스가 연결되면 `onServiceConnected()` 함수가 호출되고, 여기서 콜백 함수를 등록한다.
- 콜백 함수는 서비스에 의해 3초 간격으로 호출되며, 아규먼트로 받은 서비스 state 값을 화면에 표시한다.
- 랜덤 버튼 클릭시마다 서비스가 제공하는 랜덤 넘버를 얻어서 화면에 표시한다.

## 실행 및 결과
MyServiceClient 앱을 실행시키거나 콘솔로 아래와 같이 실행시키면 된다. (사전에 MyServiceServer 앱을 실행시키지 않아도 됨)
```sh
$ am start -n com.my.myserviceclient/.MainActivity
```

기대대로 랜덤 버튼을 누르면 랜덤값이 출력되고, 3초마다 콜백 state 값이 출력되는 것을 확인할 수 있다.  
또한 logcat을 확인해 보면, 아래와 같이 기대대로 로그가 출력되는 것을 확인할 수 있다.
```
15:20:27.541  3995  3995 I MyServiceClient: onCreate()
15:20:27.593  3995  3995 I MyServiceClient: onStart()
15:20:27.593  3995  3995 I MyServiceClient: bindToMyRemoteService()
15:20:27.737  4015  4015 I MyServiceServer: onBind()
15:20:27.739  3995  3995 I MyServiceClient: onServiceConnected() Service is bounded
15:20:27.740  4015  4035 D MyServiceServer: registerCallback: true
15:20:27.744  4015  4015 I MyServiceServer: Call callback function with state: 1
15:20:27.744  4015  4015 D MyServiceServer: callRegisteredCallback() state:1
15:20:27.744  4015  4015 I MyServiceServer: Call onMyServiceStateChanged() with state: 1
15:20:27.744  3995  4007 I MyServiceClient: onMyServiceStateChanged() state: 1
15:20:30.532  4015  4035 I MyServiceServer: getRandomNumber() return randomNum: 583
15:20:30.532  3995  3995 I MyServiceClient: Got randomNum: 583
15:20:30.752  4015  4015 I MyServiceServer: Call callback function with state: 2
15:20:30.752  4015  4015 D MyServiceServer: callRegisteredCallback() state:2
15:20:30.752  4015  4015 I MyServiceServer: Call onMyServiceStateChanged() with state: 2
15:20:30.752  3995  4034 I MyServiceClient: onMyServiceStateChanged() state: 2
15:20:32.333  4015  4035 I MyServiceServer: getRandomNumber() return randomNum: 497
15:20:32.333  3995  3995 I MyServiceClient: Got randomNum: 497
15:20:33.756  4015  4015 I MyServiceServer: Call callback function with state: 3
15:20:33.756  4015  4015 D MyServiceServer: callRegisteredCallback() state:3
15:20:33.756  4015  4015 I MyServiceServer: Call onMyServiceStateChanged() with state: 3
15:20:33.756  3995  4136 I MyServiceClient: onMyServiceStateChanged() state: 3
15:20:35.632  4015  4035 I MyServiceServer: getRandomNumber() return randomNum: 424
15:20:35.632  3995  3995 I MyServiceClient: Got randomNum: 424
15:20:36.760  4015  4015 I MyServiceServer: Call callback function with state: 4
15:20:36.760  4015  4015 D MyServiceServer: callRegisteredCallback() state:4
15:20:36.760  4015  4015 I MyServiceServer: Call onMyServiceStateChanged() with state: 4
15:20:36.760  3995  4008 I MyServiceClient: onMyServiceStateChanged() state: 4
15:20:39.764  4015  4015 I MyServiceServer: Call callback function with state: 5
15:20:39.764  4015  4015 D MyServiceServer: callRegisteredCallback() state:5
15:20:39.764  4015  4015 I MyServiceServer: Call onMyServiceStateChanged() with state: 5
15:20:39.764  3995  4008 I MyServiceClient: onMyServiceStateChanged() state: 5
15:20:41.286  3995  3995 I MyServiceClient: onStop() Unbind service
15:20:41.287  4015  4027 D MyServiceServer: unregisterCallback: true
```
