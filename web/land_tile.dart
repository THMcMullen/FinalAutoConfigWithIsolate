library land_tile;

import 'dart:web_gl' as webgl;
import 'utils.dart' as utils;
import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';

import 'contour_tracing.dart';
import 'water.dart';


class land_tile {

  int genTime;
  int runTime;

  int res = 0;

  //Allows for a cleaner linking of attributes and uniforms
  Map<String, int> attribute;
  Map<String, int> uniforms;

  //vertex shader and fragment shader
  String vertex;
  String fragment;

  var attrib;
  var unif;

  var indices;
  var vertices;
  var normals;
  var numberOfTri = 0;

  webgl.Program shader;
  webgl.RenderingContext gl;

  int locX;
  int locY;

  var heightMap;
  bool init = false;

  var above;
  var below;
  var left;
  var right;

  var waterBlob;
  
  bool waterRender = false;
  
  //water state says how water is acting on a tile, so if it is there, and if it is running
  int waterState = 0;
  
  contour_tracing blob;
  water tileWater;

  land_tile() {

  }

  generate(int x, int y, int resolution, webgl.RenderingContext givenGL) {//start location of base tile
    locX = x;
    locY = y;
    res = resolution;
    gl = givenGL;
    


    //shaders to color the landscape based on height
    String vertex = """
        attribute vec3 aVertexPosition;
        attribute vec3 aVertexNormal;
          
        uniform mat3 uNormalMatrix;
        uniform mat4 uMVMatrix;
        uniform mat4 uPMatrix;
          
        varying vec3 vLighting;
        varying vec3 vColoring;
          
        void main(void) {
            gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
          
            vec3 ambientLight = vec3(0.6,0.6,0.6);
            vec3 directionalLightColor = vec3(0.5, 0.5, 0.75);
            vec3 directionalVector = vec3(0.85, 0.8, 0.75);
          
            vec3 transformedNormal = uNormalMatrix * aVertexNormal;
          
            float directional = max(dot(transformedNormal, directionalVector), 0.0);
            vLighting = ambientLight + (directionalLightColor * directional);
          
            vColoring = vec3(aVertexPosition);
        
      }""";

    String fragment = """
          precision mediump float;
          
          varying vec3 vLighting;
          varying vec3 vColoring;
          
          void main(void) {
              vec4 color = vec4(vColoring,1);
              float alpha = vColoring.y / 5.0;
  
              if(vColoring.y < -0.5)
                color = vec4(0.0, 0.0,1.0, 1.0+alpha );
              else if(vColoring.y < 1.5)
                color = vec4(0.3+alpha, 0.8, 0.3+alpha, 1.0);
              else
                color = vec4(0.8, 0.42, 0.42, (.6 + alpha) );
          
              gl_FragColor = color*vec4(vLighting,0.5);
              
        
      }""";

    //creates the shaders unique for the landscape
    shader = utils.loadShaderSource(gl, vertex, fragment);

    attrib = ['aVertexPosition', 'aVertexNormal'];
    unif = ['uMVMatrix', 'uPMatrix', 'uNormalMatrix'];

    attribute = utils.linkAttributes(gl, shader, attrib);
    uniforms = utils.linkUniforms(gl, shader, unif);


    //print("Grid at X: $locX / Y: $locY ready to go");
  }

  void CreateHeightMap(landCon) {

    DateTime temp = new DateTime.now();
    //when creating a new tile, check to see if it has neighbours
    //check above
    if (locX + 1 < landCon.length) {
      if (landCon[locX + 1][locY] != null) {
        if (landCon[locX + 1][locY].init == true) {
          above = landCon[locX + 1][locY];
        }
      }
    }
    //check below
    if (locX - 1 >= 0) {
      if (landCon[locX - 1][locY] != null) {
        if (landCon[locX - 1][locY].init == true) {
          below = landCon[locX - 1][locY];
        }
      }
    }
    //check left
    if (locY - 1 >= 0) {
      if (landCon[locX][locY - 1] != null) {
        if (landCon[locX][locY - 1].init == true) {
          left = landCon[locX][locY - 1];
        }
      }
    }
    //check right
    if (locY + 1 < landCon[locX].length) {
      if (landCon[locX][locY + 1] != null) {
        if (landCon[locX][locY + 1].init == true) {
          right = landCon[locX][locY + 1];
          //print("left");
        }
      }
    }

    heightMap = new List(res);
    for (int i = 0; i < res; i++) {
      heightMap[i] = new List(res);
      for (int j = 0; j < res; j++) {
        heightMap[i][j] = 0.0;
      }
    }

    var height = 10;

    var rng = new math.Random();

    int sideLength2 = res - 1;
    int grid_cnt = 0;
    int Erosion_delay = 2;

    double r = 10.0;
    double Roughness = 0.55;
    double e = 0.55;

    for (int sideLength = res - 1; sideLength >= 2; sideLength = sideLength ~/ 2, height /= 2) {

      int halfSide = sideLength ~/ 2;
      int halfSide2 = sideLength2 ~/ 2;
      int QSide2 = halfSide2 ~/ 2;

      for (int x = 0; x < res - 1; x += sideLength) {
        for (int y = 0; y < res - 1; y += sideLength) {

          double avg = heightMap[x][y] + heightMap[x + sideLength][y] + heightMap[x][y + sideLength] + heightMap[x + sideLength][y + sideLength];

          avg /= 4.0;

          double offset = (-height) + rng.nextDouble() * (height - (-height));
          heightMap[x + halfSide][y + halfSide] = avg + offset;

        }
      }

      for (int x = 0; x < res; x += halfSide) {
        for (int y = (x + halfSide) % sideLength; y < res; y += sideLength) {

          double avg = heightMap[(x - halfSide + res) % res][y] + heightMap[(x + halfSide) % res][y] + heightMap[x][(y + halfSide) % res] + heightMap[x][(y - halfSide + res) % res];

          avg /= 4.0;

          double offset = (-height) + rng.nextDouble() * (height - (-height));
          heightMap[x][y] = avg + offset;

          if (above != null && x == res - 1) {
            heightMap[res - 1][y] = above.heightMap[0][y ~/ (res / above.res)];
          }
          if (below != null && x == 0) {
            heightMap[0][y] = below.heightMap[below.res - 1][y ~/ (res / below.res)];
          }
          if (left != null && y == 0) {
            heightMap[x][0] = left.heightMap[x ~/ (res / left.res)][left.res - 1];
          }
          if (right != null && y == res - 1) {
            heightMap[x][res - 1] = right.heightMap[x ~/ (res / right.res)][0];
          }


        }
      }
    }

    //print("Grid at X: $locX / Y: $locY ready to render, resolution: $res");

    init = true;

    genTime = new DateTime.now().difference(temp).inMilliseconds.abs();

    //print(genTime);

  }

  void CreateObject(landCon) {

    DateTime temp = new DateTime.now();

    //print("creating object at X: $locX, Y: $locY, with res: $res");

    //waterBlob = new blob(gl, heightMap, res, locX, locY);


    //when creating a new tile, check to see if it has neighbours
    //check above
    if (locX + 1 < landCon.length) {
      if (landCon[locX + 1][locY] != null) {
        if (landCon[locX + 1][locY].init == true) {
          above = landCon[locX + 1][locY];
        }
      }
    }
    //check below
    if (locX - 1 >= 0) {
      if (landCon[locX - 1][locY] != null) {
        if (landCon[locX - 1][locY].init == true) {
          below = landCon[locX - 1][locY];
        }
      }
    }
    //check left
    if (locY - 1 >= 0) {
      if (landCon[locX][locY - 1] != null) {
        if (landCon[locX][locY - 1].init == true) {
          left = landCon[locX][locY - 1];
        }
      }
    }
    //check right
    if (locY + 1 < landCon[locX].length) {
      if (landCon[locX][locY + 1] != null) {
        if (landCon[locX][locY + 1].init == true) {
          right = landCon[locX][locY + 1];
          //print("left");
        }
      }
    }

    //draw only the core part of the object, not the out parts
    //as the outer parts are based on the sorounding tiles

    var pos;
    var index = new List();
    var vert = new List();
    var norm = new List();

    indices = gl.createBuffer();
    vertices = gl.createBuffer();
    normals = gl.createBuffer();

    for (double i = 0.0; i < res; i++) {
      for (double j = 0.0; j < res; j++) {
        vert.add(i * (128 / (res - 1)) + (128 * locX) - (5 * 128));// + (locX*res) - res);
        vert.add(heightMap[i.toInt()][j.toInt()]);
        vert.add(j * (128 / (res - 1)) + (128 * locY) - (5 * 128));// + (locY*res) - res);
      }
    }

    for (int i = 0; i < res - 1; i++) {
      for (int j = 0; j < res - 1; j++) {

        //the possition of the vertic in the indice array we want to draw.
        pos = i * res + j;

        //top half of square
        index.add(pos);
        index.add(pos + 1);
        index.add(pos + res);

        //bottem half of square
        index.add(pos + res);
        index.add(pos + res + 1);
        index.add(pos + 1);
      }
    }

    for (int i = 0; i < res; i++) {
      for (int j = 0; j < res; j++) {

        var r = new Vector3.zero();

        r.normalize();

        norm.add(r.x);
        norm.add(r.y);
        norm.add(r.z);

      }
    }

    //base of the object is set up, now to create the edges
    if (left != null && left.res < res) {
      //the tile above has a higher res so create simple edges
      //print("making right edges");
      for (int i = 0; i < res - 1; i += 2) {
        for (int j = 0; j < 1; j++) {
          //the possition of the vertic in the indice array we want to draw.
          pos = i * res + j;
          if (i == 0) {
            index.add(pos);
            index.add(pos + res + 1);
            index.add(pos + 2);
          } else {
            index.add(pos);
            index.add(pos + res + 1);
            index.add(pos + 1);
          }
          index.add(pos);
          index.add(pos + res + 1);
          index.add(pos + res + res);
          if (i == res - 3) {
            index.add(pos + res + 1);
            index.add(pos + res + res);
            index.add(pos + res + res + 2);
          } else {
            index.add(pos + res + 1);
            index.add(pos + res + res + 1);
            index.add(pos + res + res);
          }
        }
      }
    } else {
      //use the defult indices, as there is nothing above to worry about, or the other tile will do the work
      for (int i = 0; i < res - 1; i++) {
        for (int j = 0; j < 1; j++) {
          //the possition of the vertic in the indice array we want to draw.
          pos = i * res + j;

          //top half of square
          index.add(pos);
          index.add(pos + 1);
          index.add(pos + res);

          //bottem half of square
          index.add(pos + res);
          index.add(pos + res + 1);
          index.add(pos + 1);
        }
      }
    }
    if (right != null && right.res < res) {
      //print("making left edges");
      for (int i = 0; i < res - 1; i += 2) {
        for (int j = res - 2; j < res - 1; j++) {
          //the possition of the vertic in the indice array we want to draw.
          pos = i * res + j;

          //top half of square
          if (i == 0) {
            index.add(pos - 1);
            index.add(pos + 1);
            index.add(pos + res);
          } else {
            index.add(pos);
            index.add(pos + 1);
            index.add(pos + res);
          }
          index.add(pos + 1);
          index.add(pos + res);
          index.add(pos + res + res + 1);
          if (i == res - 3) {
            index.add(pos + res);
            index.add(pos + res + res - 1);
            index.add(pos + res + res + 1);
          } else {
            index.add(pos + res);
            index.add(pos + res + res + 1);
            index.add(pos + res + res);
          }

        }
      }
    } else {
      for (int i = 0; i < res - 1; i++) {
        for (int j = res - 2; j < res - 1; j++) {
          //the possition of the vertic in the indice array we want to draw.
          pos = i * res + j;

          //top half of square
          index.add(pos);
          index.add(pos + 1);
          index.add(pos + res);

          //bottem half of square
          index.add(pos + res);
          index.add(pos + res + 1);
          index.add(pos + 1);
        }
      }
    }

    if (below != null && below.res < res) {
      //print("making below edges");
      for (int i = 0; i < 1; i++) {
        for (int j = 1; j < res - 2; j += 2) {
          //the possition of the vertic in the indice array we want to draw.
          pos = i * res + j;

          //top half of square
          index.add(pos + 1);
          index.add(pos + res + 1);
          index.add(pos + res);

          index.add(pos + 1);
          index.add(pos + res);
          index.add(pos - 1);

          index.add(pos + res);
          index.add(pos + res - 1);
          index.add(pos - 1);


        }
      }
    } else {
      for (int i = 0; i < 1; i++) {
        for (int j = 0; j < res - 1; j++) {
          //the possition of the vertic in the indice array we want to draw.
          pos = i * res + j;

          //top half of square
          index.add(pos);
          index.add(pos + 1);
          index.add(pos + res);

          //bottem half of square
          index.add(pos + res);
          index.add(pos + res + 1);
          index.add(pos + 1);
        }
      }
    }

    if (above != null && above.res < res) {
      //print("making above edges");
      for (int i = res - 2; i < res - 1; i++) {
        for (int j = 1; j < res - 2; j += 2) {
          //the possition of the vertic in the indice array we want to draw.
          pos = i * res + j;

          //top half of square
          index.add(pos + 1);
          index.add(pos + 2);
          index.add(pos + res + 1);

          index.add(pos + res + 1);
          index.add(pos);
          index.add(pos + res - 1);


          index.add(pos + 1);
          index.add(pos);
          index.add(pos + res + 1);


        }
      }
    } else {
      for (int i = res - 2; i < res - 1; i++) {
        for (int j = 0; j < res - 1; j++) {
          //the possition of the vertic in the indice array we want to draw.
          pos = i * res + j;

          //top half of square
          index.add(pos);
          index.add(pos + 1);
          index.add(pos + res);

          //bottem half of square
          index.add(pos + res);
          index.add(pos + res + 1);
          index.add(pos + 1);
        }
      }
    }

    gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, indices);
    gl.bufferDataTyped(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(index), webgl.STATIC_DRAW);

    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, vertices);
    gl.bufferDataTyped(webgl.ARRAY_BUFFER, new Float32List.fromList(vert), webgl.STATIC_DRAW);

    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, normals);
    gl.bufferData(webgl.ARRAY_BUFFER, new Float32List.fromList(norm), webgl.STATIC_DRAW);

    numberOfTri = index.length;

    index = null;
    vert = null;
    norm = null;

    init = true;

    runTime = new DateTime.now().difference(temp).inMilliseconds.abs();
    if(locX == 3 && locY == 3){
      addWater();
    }
  }
  
  addWater(){
    

    tileWater = new water(gl, heightMap, res, locX, locY, waterState);
    
    waterRender = true;
        
  }

  downGrade(landCon) {
    //print("Down Grade");

    res = (res ~/ 2) + 1;
    
    if (locX + 1 < landCon.length) {
       if (landCon[locX + 1][locY] != null) {
         if (landCon[locX + 1][locY].init == true) {
           above = landCon[locX + 1][locY];
         }
       }
     }
     //check below
     if (locX - 1 >= 0) {
       if (landCon[locX - 1][locY] != null) {
         if (landCon[locX - 1][locY].init == true) {
           below = landCon[locX - 1][locY];
         }
       }
     }
     //check left
     if (locY - 1 >= 0) {
       if (landCon[locX][locY - 1] != null) {
         if (landCon[locX][locY - 1].init == true) {
           left = landCon[locX][locY - 1];
         }
       }
     }
     //check right
     if (locY + 1 < landCon[locX].length) {
       if (landCon[locX][locY + 1] != null) {
         if (landCon[locX][locY + 1].init == true) {
           right = landCon[locX][locY + 1];
           //print("left");
         }
       }
     }

    var tempList = new List(res);
    for (int i = 0; i < res; i++) {
      tempList[i] = new List(res);
      for (int j = 0; j < res; j++) {
        tempList[i][j] = 0.0;
      }
    }
    

    

    for (int i = 0; i < heightMap.length; i += 2) {
      for (int j = 0; j < heightMap[i].length; j += 2) {
        tempList[i ~/ 2][j ~/ 2] = heightMap[i][j];
        

         
         
      }
    }

    heightMap = tempList;
    tempList = null;
    //CreateObject(landCon);
  }

  void upGrade(landCon) {
    //print("Up Grade");

    //when creating a new tile, check to see if it has neighbours
    //check above
    if (locX + 1 < landCon.length) {
      if (landCon[locX + 1][locY] != null) {
        if (landCon[locX + 1][locY].init == true) {
          above = landCon[locX + 1][locY];
        }
      }
    }
    //check below
    if (locX - 1 >= 0) {
      if (landCon[locX - 1][locY] != null) {
        if (landCon[locX - 1][locY].init == true) {
          below = landCon[locX - 1][locY];
        }
      }
    }
    //check left
    if (locY - 1 >= 0) {
      if (landCon[locX][locY - 1] != null) {
        if (landCon[locX][locY - 1].init == true) {
          left = landCon[locX][locY - 1];
        }
      }
    }
    //check right
    if (locY + 1 < landCon[locX].length) {
      if (landCon[locX][locY + 1] != null) {
        if (landCon[locX][locY + 1].init == true) {
          right = landCon[locX][locY + 1];
          //print("left");
        }
      }
    }

    res = (res * 2) - 1;
    var height = (1 / res) * 10;
    var rng = new math.Random();

    var tempList = new List(res);
    for (int i = 0; i < res; i++) {
      tempList[i] = new List(res);
      for (int j = 0; j < res; j++) {
        tempList[i][j] = 0.0;
        if (i % 2 == 0 && j % 2 == 0) {
          tempList[i][j] = heightMap[i ~/ 2][j ~/ 2];
        }
        if (above != null && i == res - 1) {
          tempList[res - 1][j] = above.heightMap[0][j ~/ (res / above.res)];
        }
        if (below != null && i == 0) {
          tempList[0][j] = below.heightMap[below.res - 1][j ~/ (res / below.res)];
        }
        if (left != null && j == 0) {
          tempList[i][0] = left.heightMap[i ~/ (res / left.res)][left.res - 1];
        }
        if (right != null && j == res - 1) {
          tempList[i][res - 1] = right.heightMap[i ~/ (res / right.res)][0];
        }
      }
    }
    
    for (int i = 1; i < res - 1; i += 2) {
      for (int j = 1; j < res - 1; j += 2) {

        double avg = tempList[i - 1][j - 1] + tempList[i - 1][j + 1] + tempList[i + 1][j - 1] + tempList[i + 1][j + 1];

        avg /= 4.0;

        double offset = (-height) + rng.nextDouble() * (height - (-height));
        tempList[i][j] = avg + offset;



      }
    }

    for (int i = 0; i < res - 1; i += 1) {
      for (int j = (i + 1) % 2; j < res - 1; j += 2) {
        double avg = tempList[(i - 1 + res) % res][j] + tempList[(i + 1) % res][j] + tempList[i][(j + 1) % res] + tempList[i][(j - 1 + res) % res];

        avg /= 4.0;

        double offset = (-height) + rng.nextDouble() * (height - (-height));
        tempList[i][j] = avg + offset;

      }
    }
    
    for (int i = 0; i < res; i++) {   
      for (int j = 0; j < res; j++) {
        if (above != null && i == res - 1) {
          tempList[res - 1][j] = above.heightMap[0][j ~/ (res / above.res)];
        }
        if (below != null && i == 0) {
          tempList[0][j] = below.heightMap[below.res - 1][j ~/ (res / below.res)];
        }
        if (left != null && j == 0) {
          tempList[i][0] = left.heightMap[i ~/ (res / left.res)][left.res - 1];
        }
        if (right != null && j == res - 1) {
          tempList[i][res - 1] = right.heightMap[i ~/ (res / right.res)][0];
        }
      }
    }
    heightMap = tempList;
    tempList = null;
    //CreateObject(landCon);

  }
  
  update(){
    if(locX == 3 && locY == 3){
      if(tileWater.map != null){  
        //print("update");
        tileWater.waterUpdate();
      }
    }
  }

  draw(Matrix4 viewMat, Matrix4 projectMat) {

    //print("render");

    gl.useProgram(shader);

    utils.setMatrixUniforms(gl, viewMat, projectMat, uniforms['uPMatrix'], uniforms['uMVMatrix'], uniforms['uNormalMatrix']);

    gl.enableVertexAttribArray(attribute['aVertexPosition']);
    gl.bindBuffer(webgl.ARRAY_BUFFER, vertices);
    gl.vertexAttribPointer(attribute['aVertexPosition'], 3, webgl.FLOAT, false, 0, 0);

    gl.enableVertexAttribArray(attribute['aVertexNormal']);
    gl.bindBuffer(webgl.ARRAY_BUFFER, normals);
    gl.vertexAttribPointer(attribute['aVertexNormal'], 3, webgl.FLOAT, false, 0, 0);

    gl.bindBuffer(webgl.ELEMENT_ARRAY_BUFFER, indices);
    gl.drawElements(webgl.TRIANGLES, numberOfTri, webgl.UNSIGNED_SHORT, 0);
    
    if(waterRender){
      tileWater.drawWater(viewMat, projectMat);
    }
 
  }

}
