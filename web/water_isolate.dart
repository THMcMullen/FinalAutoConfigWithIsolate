import 'dart:isolate';
import 'dart:async';

import 'contour_tracing.dart';

main(List<String> args, SendPort sendPort) {
  ReceivePort receivePort = new ReceivePort();
  sendPort.send(receivePort.sendPort);
  
  bool init = false;
  var grid;
  double waterLevel = 0.5;
  
  update(){
    print("update");
    //sendPort.send('ECHO: new vertices go here');
    //new Future.delayed(const Duration(milliseconds: 15), update());
  }
  
  initilize(layout){
    print(layout);
    contour_tracing blob;
    blob = new contour_tracing(waterLevel, layout);
    grid = blob.blobMap;
    init = true;
    
    var wVert;
    var waterIndices;
    var X = 129;
    var Y = 129;
    var indMap;
    for (int i = 1; i < grid.length - 1; i++) {
      for (int j = 1; j < grid[i].length - 1; j++) {
        if (grid[i][j] != 0 && grid[i][j] != 200) {
          if (grid[i + 1][j + 1] == 0) {
            grid[i + 1][j + 1] = 200;
          }
          if (grid[i + 1][j] == 0) {
            grid[i + 1][j] = 200;
          }
          if (grid[i + 1][j - 1] == 0) {
            grid[i + 1][j - 1] = 200;
          }
          if (grid[i][j + 1] == 0) {
            grid[i][j + 1] = 200;
          }
          if (grid[i][j - 1] == 0) {
            grid[i][j - 1] = 200;
          }
          if (grid[i - 1][j + 1] == 0) {
            grid[i - 1][j + 1] = 200;
          }
          if (grid[i - 1][j] == 0) {
            grid[i - 1][j] = 200;
          }
          if (grid[i - 1][j - 1] == 0) {
            grid[i - 1][j - 1] = 200;
          }
        }
      }
    }

    indMap = new List(grid.length - 1);
    for (int x = 0; x < grid.length - 1; x++) {
      indMap[x] = new List(grid[x].length - 1);
      for (int y = 0; y < grid[x].length - 1; y++) {
        indMap[x][y] = 0;
      }
    }

    for (double x = 0.0; x < X; x++) {
      for (double y = 0.0; y < Y; y++) {
        if (grid[x.toInt()+1][y.toInt()+1] != 0) {
          wVert.add(y);
          indMap[x.toInt()][y.toInt()] = wVert.length;
          wVert.add(-0.5);
          wVert.add(x);
        }
      }
    }
    
       for(int i = 0; i < X-1; i++){
         for(int j = 0; j < Y-1; j++){
           if(grid[i+1][j+1] != 0){
             if(grid[i+2][j+1] != 0){
               int current = null;
               int cm1 = null;
               int cp1 = null;
               int currentp1 = null;
               for(int k = 0; k < wVert.length; k+=3){
                  if(wVert[k] == j && wVert[k+2] == i){
                    current = k~/3;
                  }else if(wVert[k] == j+1 && wVert[k+2] == i){
                    currentp1 = k~/3;
                  }else if(wVert[k] == j && wVert[k+2] == i+1){
                    cm1 = k~/3;
                  }else if(wVert[k] == j+1 && wVert[k+2] == i+1){
                    cp1 = k~/3;
                  }
               }
               if(cp1 == null || cm1 == null || current == null || currentp1 == null){
                  //print("$i:, \n $j:");
               }else{               
                 waterIndices.add(currentp1);
                 waterIndices.add(cm1);
                 waterIndices.add(cp1);
                 waterIndices.add(current);
                 waterIndices.add(currentp1);
                 waterIndices.add(cm1);
               }
             }
           }
         }
       }
      var waterMap = new List(grid.length);

    for (int i = 0; i < grid.length; i++) {
      var c = 0;
      waterMap[i] = new List();
      waterMap[i].add(0);
      for (int j = 1; j < grid[i].length + 1; j++) {
        if (grid[i][j - 1] != 0 && grid[i][j - 1] != 200) {
          c++;
          waterMap[i].add(j - 1);
        } else {
          waterMap[i].add(0);
        }
      }
      waterMap[i][0] = c;
    }

    int tempCounter = 0;

    for (double x = 0.0; x < X; x++) {
      for (double y = 0.0; y < Y; y++) {
        if (grid[x.toInt()+1][y.toInt()+1] != 0) {
          wVert[tempCounter] =
              (y * (128 / (X - 1)) + (128 * 3) - (5 * 128));
          tempCounter += 2;

          wVert[tempCounter] =
              (x * (128 / (Y - 1)) + (128 * 3) - (5 * 128));
          tempCounter++;
        }
      }
    }
    //print(waterIndices);
    sendPort.send([1, 0]);
    //update();
  }

  
  receivePort.listen((msg) {
    print("Isolate has started");
    if(init){
      update();
    }else{
      initilize(msg);
    }
    //initilize(msg);
    //sendPort.send('ECHO: $msg');
  });
}