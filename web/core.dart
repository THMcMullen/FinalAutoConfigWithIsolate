//controlls the way in which data is proccessed
//optermises tile design
//the way in which data flows, and changes

library core;

import 'dart:web_gl';
import 'dart:html';

import 'camera.dart' as cam;
import 'land_tile.dart';

import 'package:vector_math/vector_math.dart';

class core{
  
  RenderingContext gl;
  CanvasElement canvas;
  
  int baseSystemSize;//defines the ratio of the center tiles which all other tiles are based from
  List center;
  List oldPos = [0.0 ,0.0];
  List pos = [0.0 ,0.0];
  
  List container; //Stores a link to all land tiles, allowing for easy access;
  double coreTile;
  double secondTile;
  double lastTile;
  int containerSize;
  int gridSize;
  double ratio;
  int quality;
  int area;
  
  cam.camera camera;
  
  Matrix4 projectionMat;
  
  core(RenderingContext givenGl, CanvasElement givenCanvas){
    gl = givenGl;
    canvas = givenCanvas;
    camera = new cam.camera(canvas); 
    
    projectionMat = makePerspectiveMatrix(45, (canvas.width / canvas.height), 1, 10000);
    setPerspectiveMatrix( projectionMat, 45, (canvas.width / canvas.height), 1.0, 10000.0);
    
    gl.clearColor(1.0, 1.0, 1.0, 1.0);
    gl.clearDepth(1.0);
    gl.enable(RenderingContext.DEPTH_TEST);
  }
  
  initState(){
    ratio = quality / (area + quality);
    print("Ratio is : $ratio");
    if (ratio >= 0.5) {
      baseSystemSize = 129;
    } else if (ratio > 0.25) {
      baseSystemSize = 65;
    } else {
      baseSystemSize = 33;
    }
    land_tile baseTile = new land_tile();
    //auto config creation aspect runs here
    baseTile.generate(0, 0, baseSystemSize, gl); //start location of base tile

    container = new List();
    container.add(new List<land_tile>());
    container[0].add(baseTile);

    baseTile.CreateHeightMap(container);
    baseTile.CreateObject(container);

    print(baseTile.genTime);
    print(baseTile.runTime);

    int genTime = baseTile.genTime + baseTile.runTime;

    gridSize = (1000 / genTime).round();

    print("base system size: $baseSystemSize");
    print("grid size is: $gridSize");

    baseTile = null;
  }
  
  setup(){
    print("setup");
    initState();

    container = new List();

    //based on the base system size, create defult grid

    //gridSize = 40;
    if (gridSize < 12) {
      containerSize = 4;
    } else if (gridSize < 24) {
      containerSize = 6;
    } else if (gridSize < 40) {
      containerSize = 8;
    } else if (gridSize < 80) {
      containerSize = 10;
    } else {
      containerSize = 12;
    }


    double layout = containerSize * ratio;

    for (int i = 0; i < 100; i++) {
      container.add(new List<land_tile>());
      for (int j = 0; j < 100; j++) {
        container[i].add(null);
      }
    }

    coreTile = layout / ((containerSize) / 2);
    secondTile = layout / ((containerSize) / 4);
    lastTile = layout / ((containerSize) / 6);


    print("  coreTile: $coreTile");
    print("secondTile: $secondTile");
    print("  lastTile: $lastTile");

    double center = (containerSize - 1) / 2;
    print("Center: $center");
    for (int i = 0; i < container.length; i++) {
      for (int j = 0; j < container[i].length; j++) {
        double difI = i - center;
        double difJ = j - center;

        difI = difI.abs();
        difJ = difJ.abs();


        if (difI + difJ <= coreTile) {
          container[i][j] = new land_tile();
          container[i][j].generate(i, j, baseSystemSize, gl);
        } else if (difI + difJ <= secondTile ||
            (((difI <= coreTile + 0.5) && (difJ <= coreTile + 0.5)) &&
                containerSize != 4)) {
          container[i][j] = new land_tile();
          int tBaseSystemSize = ((baseSystemSize + 1) ~/ 2) < 33
              ? 33
              : ((baseSystemSize + 1) ~/ 2);
          container[i][j].generate(i, j, tBaseSystemSize, gl);
        } else if ((difI + difJ <= lastTile) && containerSize != 4) {
          container[i][j] = new land_tile();
          int tBaseSystemSize = (((baseSystemSize) ~/ 4) + 1) < 33
              ? 33
              : (((baseSystemSize) ~/ 4) + 1);
          container[i][j].generate(i, j, tBaseSystemSize, gl);
        }

      }
    }

    List temptwo;
    temptwo = new List();
    for (int i = 0; i < 100; i++) {
      temptwo.add(new List());
      for (int j = 0; j < 100; j++) {
        temptwo[i].add(0);
      }
    }

    for (int i = 0; i < container.length; i++) {
      for (int j = 0; j < container[i].length; j++) {
        if (container[i][j] != null) {
          temptwo[i][j] = container[i][j].res;
        }
      }
    }

    //now to create the tiles
    //create the tiles with the lowest resolution first
    for (int i = 0; i < container.length; i++) {
      for (int j = 0; j < container[i].length; j++) {
        if (container[i][j] != null) {
          if (container[i][j].res == ((baseSystemSize) ~/ 4) + 1) {
            container[i][j].CreateHeightMap(container);
          }
        }
      }
    }

    for (int i = 0; i < container.length; i++) {
      for (int j = 0; j < container[i].length; j++) {
        if (container[i][j] != null) {
          if (container[i][j].res == (baseSystemSize + 1) ~/ 2) {
            container[i][j].CreateHeightMap(container);
          }
        }
      }
    }
    for (int i = 0; i < container.length; i++) {
      for (int j = 0; j < container[i].length; j++) {
        if (container[i][j] != null) {
          if (container[i][j].res == baseSystemSize) {
            container[i][j].CreateHeightMap(container);
          }
        }
      }
    }
    for (int i = 0; i < container.length; i++) {
      for (int j = 0; j < container[i].length; j++) {
        if (container[i][j] != null) {
          if (container[i][j].res == ((baseSystemSize) ~/ 4) + 1) {
            container[i][j].CreateObject(container);
          }
        }
      }
    }

    for (int i = 0; i < container.length; i++) {
      for (int j = 0; j < container[i].length; j++) {
        if (container[i][j] != null) {
          if (container[i][j].res == (baseSystemSize + 1) ~/ 2) {
            container[i][j].CreateObject(container);
          }
        }
      }
    }
    for (int i = 0; i < container.length; i++) {
      for (int j = 0; j < container[i].length; j++) {
        if (container[i][j] != null) {
          if (container[i][j].res == baseSystemSize) {
            container[i][j].CreateObject(container);
          }
        }
      }
    }
    
    for (int i = 0; i < container.length; i++) {
      for (int j = 0; j < container[i].length; j++) {
        if (container[i][j] != null) {
          if(container[i][j].res == 129){
            container[i][j].waterState = 3;
          }
        }
      }
    }
  }
  
  update(){
    
  }
  
  draw(){
    
  }
  
}