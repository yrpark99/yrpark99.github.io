---
title: "VS Code의 C/C++를 위한 c_cpp_properties.json 생성 자동화"
category: [C, VSCode]
toc: true
toc_label: "이 페이지 목차"
---

VS Code 용 c_cpp_properties.json 파일을 자동으로 생성하는 툴을 자작하여 공유한다.

## LSP 활성화 방법
VS Code에서 C/C++ 소스에 대하여 LSP(Language Server Protocol) 기능을 사용하기 위해서는 다음 2가지 방법이 있다.
- `compile_commands.json` 파일 사용: [C/C++ 용 LSP(Language Server Protocol) 이용하기](https://yrpark99.github.io/c/c_compiledb/) 참조
- `c_cpp_properties.json` 파일 사용: VS Code가 제공하는 프로젝트 별 C/C++ 설정  
단, 이 방법은 <font color=blue>"includePath"</font>, <font color=blue>"defines"</font>, <font color=blue>"compilerPath"</font> 등의 값을 수동으로 추가해 주어야 하는 불편함이 있는데, 이 글에서는 이를 자동화하는 자작 툴을 소개한다.

## c_cpp_properties.json 수동 설정
VS Code에서 `c_cpp_properties.json` 파일을 사용하는 경우에는 **make** 빌드 시에 사용되는 <mark style='background-color: #ffdce0'>-I</mark> 내용은 <font color=blue>"includePath"</font>에, <mark style='background-color: #ffdce0'>-D</mark> 내용은 <font color=blue>"defines"</font>에 추가해 주어야 하고, 사용하는 GCC 툴체인 경로도 <font color=blue>"compilerPath"</font>에 올바르게 설정되어 있어야 한다.  
그런데, 여러 모델에서 빌드 시스템이 복잡하고 빌드 옵션이 서로 다른 경우에는, 각 모델마다 매번 수동으로 이 파일을 설정해야 한다.
> 추가로 나 같은 경우에는 동일 모델이라도 여러 빌드 configuration이 있고 그에 따라서 C/C++ 컴파일 옵션도 달라지므로, 한 번 수작업으로 설정했더라도 빌드 configuration을 변경하면 **c_cpp_properties.json** 파일도 그에 맞게 다시 수정해야 했다.

이와 같이 **c_cpp_properties.json** 파일을 수동으로 설정하는 작업이 번거롭기도 하고, VS Code 미숙련자도 쉽게 구축할 수 있는 방법이 없을까 생각하다가 🤔, 아예 자동으로 **c_cpp_properties.json** 파일을 완전히 작성해 주는 파이썬 코드를 작성하게 되었다. (단, **make** 빌드 시스템을 사용하는 경우임)

## c_cpp_properties.json 자동화 툴
아래와 같이 파이썬 코드를 작성하였고, 사용하는 프로젝트의 저장소에도 올렸다. (파일 이름은 **vscode_json.py**로 했고, 코드에 충분히 주석을 달았으므로, 여기서는 코드 설명은 생략함)
```python
#!/usr/bin/python3
# -*- coding: utf-8 -*-

# 사용 예
# $ ./vscode_json.py -j

import json
import os
import subprocess
import sys

from typing import Any, Dict, List, Set, Tuple

includePath: Set[str] = set()
defines: Set[str] = set()
browsePath: Set[str] = set()
cStandard: Set[str] = set()
cppStandard: Set[str] = set()
gccPath: str = ""

def getBuildOutput(command: List[str]) -> List[str]:
    """입력 명령을 실행시키고, 출력 결과를 줄 단위로 얻어서 리턴한다."""
    proc = subprocess.Popen(command, stdout = subprocess.PIPE)
    outString, _ = proc.communicate()
    if proc.returncode != 0:
        print("Fail to build.")
        return [""]
    outputLines = outString.decode('utf-8').splitlines()
    return outputLines

def addOneIncludePathOrDefines(lineSliced: str, include_define: Set[str]) -> str:
    """
    "-I" 또는 "-D"로 시작하는 입력 줄에서 맨 앞의 1개 내용을 추출하여 입력 set에 추가한 후, 나머지 줄 내용을 리턴한다.
    -I, -D의 다음과 같은 사용 예들을 모두 지원한다. (-DDEBUG, -D'DEBUG', -D"DEBUG", -D DEBUG, -D 'DEBUG', -D "DEBUG")
    """
    # -I, -D 바로 뒤에 공백이 있으면 제거한다.
    lineStr = lineSliced[2:].lstrip()

    # 각 경우에 대한 내용의 시작 위치와 종료 위치를 얻는다.
    if lineStr.startswith("'"):
        startIndex = 1
        endIndex = startIndex + lineStr[startIndex:].find("'")
        if endIndex == 0:
            return ""
    elif lineStr.startswith('"'):
        startIndex = 1
        endIndex = startIndex + lineStr[startIndex:].find('"')
        if endIndex == 0:
            return ""
    else:
        startIndex = 0
        endIndex = lineStr[startIndex:].find(" ")
        if endIndex == -1:
            endIndex = len(lineStr[startIndex:])

    if lineSliced.startswith("-I"):
        # Include 경로이면 실제 존재하는 경로인 경우에만 절대 경로로 추가한다.
        command = ["readlink", "-e", "-n", lineStr[startIndex:endIndex]]
        proc = subprocess.Popen(command, stdout = subprocess.PIPE)
        outString, _ = proc.communicate()
        if proc.returncode == 0:
            out = outString.decode('utf-8')
            include_define.add(out)
    else:
        # 종료 위치 전까지의 내용을 입력 set에 추가한 후, 나머지 줄의 내용을 리턴한다.
        include_define.add(lineStr[startIndex:endIndex])

    # 이번에 처리한 내용은 제거하고, 이후의 내용을 리턴한다.
    return lineStr[endIndex:]

def getStandardVersion(lineSliced: str) -> str:
    """
    "-std="로 시작하는 입력 줄에서 표준 C/C++ 번호를 추출하여 set에 추가한 후, 나머지 줄 내용을 리턴한다.
    """
    endIndex = lineSliced.find(" ")
    if endIndex == -1:
        endIndex = len(lineSliced)
    stdVerStr = lineSliced[5:endIndex]

    # gnu++이나 c++과 같이 "++" 문자열이 있으면 C++ 정보로, 없으면 C 정보로 추가한다.
    if stdVerStr.find("++") == -1:
        cStandard.add(stdVerStr)
    else:
        cppStandard.add(stdVerStr)

    return lineSliced[endIndex:]

def parseCompileOptions(line: str) -> None:
    """입력 줄에서 gcc 실행 경로를 얻어서 gccPath에 저장하고, include와 define 값을 추출해서 해당 set에 추가한다."""
    global gccPath

    # gcc/g++ 실행 경로를 추출한다. (만약에 "/"로 시작하지 않으면 PATH를 통해서 경로를 얻음)
    index = line.find(" ")
    if index == -1:
        return
    gccCmd = line[:index]
    if gccCmd.startswith("/"):
        gccPath = gccCmd
    else:
        gccPath = os.popen("which " + gccCmd).read().strip('\n')
    lineOptionStr = line[index+1:]

    # 입력 줄 내용에서 모든 -I, -D, -std 내용을 해당 set에 추가한다.
    while lineOptionStr != "":
        lineOptionStr = lineOptionStr.strip()
        if lineOptionStr.startswith("-I"):
            lineOptionStr = addOneIncludePathOrDefines(lineOptionStr, includePath)
        elif lineOptionStr.startswith("-D"):
            lineOptionStr = addOneIncludePathOrDefines(lineOptionStr, defines)
        elif lineOptionStr.startswith("-std="):
            lineOptionStr = getStandardVersion(lineOptionStr)
        else:
            startIndex = lineOptionStr.find(" ")
            if startIndex == -1:
                break
            lineOptionStr = lineOptionStr[startIndex:]

def parseBuildOutput(lines: List[str]) -> int:
    """입력으로 받은 make 실행 결과 전체를 파싱하고, 파싱된 줄 수를 리턴한다."""
    # 각 줄에서 gcc 또는 g++로 빌드하는 줄이면 include, define을 찾아서 처리한다.
    builtLineNum = 0
    for line in lines:
        index = line.find(" ")
        if index == -1:
            continue
        lineCmd = line[:index]
        if lineCmd.endswith("gcc") or lineCmd.endswith("g++"):
            if "-M" in line:
                continue
            builtLineNum += 1
            parseCompileOptions(line)

    return builtLineNum

def getStandardCVersion(toolchainPath: str) -> Tuple[str, str]:
    """
    컴파일시 -std 옵션으로 지정된 C/C++ 표준 번호를 얻는다.
    지정 옵션이 없는 경우에는 임시 파일을 높은 표준 번호부터 빌드해서 에러가 발생하지 않는 C/C++ 표준 번호를 얻는다.
    """
    StdCVersion = ""
    StdCppVersion = ""

    # 컴파일 옵션에 표준 번호가 지정되어 있었으면 이 정보를 사용한다.
    if len(cStandard) > 0:
        StdCVersion = list(cStandard)[0]
    if len(cppStandard) > 0:
        StdCppVersion = list(cppStandard)[0]
    if len(cStandard) > 0 and len(cppStandard) > 0:
        return StdCVersion, StdCppVersion

    # 입력 GCC 명령이 올바르지 않으면 리턴한다.
    if not (toolchainPath.endswith("gcc") or toolchainPath.endswith("g++")):
        return StdCVersion, StdCppVersion

    # C 파일을 -std 옵션으로 높은 표준 번호부터 세팅해서 빌드 에러가 발생하지 않을 때의 표준 번호를 얻는다.
    if StdCVersion == "":
        tempCFile = open("tmp_build_test.c", "w")
        tempCFile.write("int main(){return 0;}\n")
        tempCFile.close()
        stdOptions = ["-std=c17", "-std=c11", "-std=c99", "-std=c89"]
        command = [toolchainPath, "", "tmp_build_test.c", "-o", "tmp_build_test"]
        for option in stdOptions:
            command[1] = option
            proc = subprocess.Popen(command, stderr = subprocess.DEVNULL)
            _, _ = proc.communicate()
            if proc.returncode == 0:
                StdCVersion = command[1][5:8]
                break
        os.remove("tmp_build_test.c")

    # C++ 파일을 -std 옵션으로 높은 표준 번호부터 세팅해서 빌드 에러가 발생하지 않을 때의 표준 번호를 얻는다.
    if StdCppVersion == "":
        tempCppFile = open("tmp_build_test.cpp", "w")
        tempCppFile.write("int main(){return 0;}\n")
        tempCppFile.close()
        stdOptions = ["-std=c++17", "-std=c++14", "-std=c++11", "-std=c++03", "-std=c++98"]
        command = [toolchainPath, "", "tmp_build_test.cpp", "-o", "tmp_build_test"]
        for option in stdOptions:
            command[1] = option
            proc = subprocess.Popen(command, stderr = subprocess.DEVNULL)
            _, _ = proc.communicate()
            if proc.returncode == 0:
                StdCppVersion = command[1][5:10]
                break
        os.remove("tmp_build_test.cpp")

    # 빌드된 임시 실행 파일을 삭제한다.
    os.remove("tmp_build_test")

    return StdCVersion, StdCppVersion

def writeJsonFile(jsonFileName: str) -> None:
    """VS Code 용 c_cpp_properties.json 파일을 위한 JSON 데이터를 생성하여, 입력받은 이름으로 저장한다."""
    # 표준 C/C++ 번호를 얻는다.
    stdCVer, stdCppVer = getStandardCVersion(gccPath)

    # JSON을 dictionary 타입으로 구성한다.
    outputJson: Dict[str, Any] = dict()
    outputJson["configurations"] = []
    outputJson["version"] = 4

    # JSON에서 "configurations" 항목을 구성한다.
    configDict: Dict[str, Any] = dict()
    configDict["name"] = "Linux"
    configDict["includePath"] = sorted(includePath)
    configDict["defines"] = sorted(defines)
    configDict["browse"] = dict()
    configDict["browse"]["path"] = sorted(browsePath)
    configDict["compilerPath"] = gccPath
    configDict["cStandard"]= stdCVer
    configDict["cppStandard"] = stdCppVer
    outputJson["configurations"].append(configDict)

    # Dictionary를 JSON 문자열로 변환한다.
    jsonMsg = json.dumps(outputJson, indent=4)

    # JSON 데이터를 입력 이름으로 저장한다.
    try:
        outFile = open(jsonFileName, "w")
    except:
        print("Failed to open " + jsonFileName + " file.")
        sys.exit(1)
    outFile.write(jsonMsg)
    outFile.close()

# VS Code를 위한 c_cpp_properties.json 파일을 생성한다.
if __name__ == '__main__':
    # 빌드 명령을 준비한다. (dry-run 모드로 make 실행)
    commands = ["make", "-n"]

    # 현재 경로와 프로젝트 경로가 다른 경우(다른 경로에서 이 파일을 실행시키는 경우)를 처리한다.
    curPath = os.getcwd()
    projectPath = os.path.dirname(os.path.abspath(__file__))
    if curPath == projectPath:
        jsonFileName = ".vscode/c_cpp_properties.json"
    else:
        jsonFileName = projectPath + "/" + ".vscode/c_cpp_properties.json"
        commands.append("-C")
        commands.append(projectPath)

    # 입력 아규먼트에 make 빌드 옵션이 있으면 빌드 명령에 추가한다.
    for arg in sys.argv[1:]:
        commands.append(arg)

    # 빌드 명령을 실행시키고, 출력 결과를 줄 단위로 얻는다.
    print(' '.join(commands))
    print("Dry-run building...")
    makeOutputLines = getBuildOutput(commands)
    if makeOutputLines[0] == "":
        print("No build output.")
        sys.exit(1)
    print("Dry-run building is done.")

    # 얻은 빌드 출력 결과를 파싱한다.
    print("Output parsing...")
    parsedLineNum = parseBuildOutput(makeOutputLines)
    if parsedLineNum == 0:
        print("No files are dry-run build done. At least 1 file need to be built.")
    else:
        print(f"Output parsing is done (total {parsedLineNum} lines).")

    # 파싱한 데이터를 JSON 파일로 저장한다.
    if os.path.exists(".vscode") == False:
        os.mkdir(".vscode")
    writeJsonFile(jsonFileName)
    os.system("ls -lgG " + jsonFileName)
```

참고로 위의 코드에서는 type annotation을 추가하였고, 다음과 같이 정적 분석을 한 경우에 문제가 없음을 확인하였다.
```sh
$ pip3 install mypy
$ mypy --strict vscode_json.py
```

## 맺음말
위와 같은 자동화 툴을 소스 저장소에 올려놓고, 각 프로젝트마다 사용해 보니 VS Code에서 프로젝트 별로 C/C++ 개발 환경을 아주 편하게 구축할 수 있었다. 😛
