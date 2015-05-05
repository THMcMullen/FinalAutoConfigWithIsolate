//controlls the water, launching an Isolate to create indices based on height map
library water;

import 'dart:isolate';
import 'dart:async';
import 'dart:web_gl';
import 'utils.dart' as utils;
import 'dart:typed_data';


class water {
  SendPort sendPort;
  int isoCounter = 0;
  ReceivePort receivePort = new ReceivePort();
  var map;
  bool ready = false;

  int sizeX = 0;
  int sizeY = 0;
  int startX = 0;
  int startY = 0;

  RenderingContext gl;

  Map<String, int> attributes;
  Map<String, int> uniforms;

  Map<String, int> waterAttributes;
  Map<String, int> waterUniforms;

  var waterShader;
  var shader;
  var boxVert;
  var ind;
  var norm;

  var waterIndices;
  var wVert;
  var waterVert;
  var waterInd;
  var waterNorm;
  var wNorm = new List();

  var g;
  var b;
  var h, h1;
  var u, u1;
  var v, v1;

  var X;
  var Y;

  double dt = 0.01;

  var bigArray;

  List indMap;

  int noise = 0;

  int waterState;

  int locX;
  int locY;

  temp() {
    if (sendPort == null) {
      print("Not ready yet");
      new Future.delayed(const Duration(milliseconds: 15), temp);
    } else {
      sendPort.send(map);
    }
  }

  String workerUri = 'water_isolate.dart';

  water(givenGL, passMap, res, givenLocX, givenLocY, givenState) {
    gl = givenGL;

    X = res;
    Y = res;

    locX = givenLocX;
    locY = givenLocY;

    waterState = givenState;

    String verts = """
      attribute vec3 aVertexPosition;
      attribute vec3 aVertexNormal;
  
      uniform mat3 uNormalMatrix;
      uniform mat4 uMVMatrix;
      uniform mat4 uPMatrix;

      varying vec3 vLighting;

      void main(void) {
          gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);

          vec3 ambientLight = vec3(0.6,0.6,1.0);
          vec3 directionalLightColor = vec3(0.8, 0.8, 0.8);
          vec3 directionalVector = vec3(1.0, 1.0, 1.0);

          vec3 transformedNormal = uNormalMatrix * aVertexNormal;

          float directional = max(dot(transformedNormal, directionalVector), 0.0);
          vLighting = ambientLight + (directionalLightColor * directional);
      }""";

    String frag = """
      precision mediump float;

      varying vec3 vLighting;
  
      void main(void) {

          gl_FragColor = vec4(vLighting, 1.0);

      }""";

    waterShader = utils.loadShaderSource(gl, verts, frag);

    var attrib = ['aVertexPosition', 'aVertexNormal'];
    var unif = ['uMVMatrix', 'uPMatrix', 'uNormalMatrix'];

    waterAttributes = utils.linkAttributes(gl, waterShader, attrib);
    waterUniforms = utils.linkUniforms(gl, waterShader, unif);
    if (locX == 3 && locY == 3) {
      map = passMap;
      createFluidWater();
    } else {
      createFlatWater();
    }
  }

  drawWater(viewMat, projectMat) {
    if(ready){
      gl.useProgram(waterShader);    
      utils.setMatrixUniforms(gl, viewMat, projectMat, waterUniforms['uPMatrix'], waterUniforms['uMVMatrix'], waterUniforms['uNormalMatrix']);
      
      gl.enableVertexAttribArray(waterAttributes['aVertexPosition']);
      gl.bindBuffer(ARRAY_BUFFER, waterVert);
      gl.vertexAttribPointer(waterAttributes['aVertexPosition'], 3, FLOAT, false, 0, 0);
      
      gl.enableVertexAttribArray(waterAttributes['aVertexNormal']);
      gl.bindBuffer(ARRAY_BUFFER, waterNorm);
      gl.vertexAttribPointer(waterAttributes['aVertexNormal'], 3, FLOAT, false, 0, 0);
      
      gl.bindBuffer(ELEMENT_ARRAY_BUFFER, waterInd);    
      gl.drawElements(TRIANGLES, waterIndices.length, UNSIGNED_SHORT, 0);
    }

  }
  
  waterUpdate() {}

  createFluidWater() {
    receivePort.listen((msg) {
      if (sendPort == null) {
        sendPort = msg;
      } else {
        print(msg);
        fluidWaterSetup(msg);
      }
    });

    Isolate
        .spawnUri(Uri.parse(workerUri), [], receivePort.sendPort)
        .whenComplete(temp);
  }
  
  fluidWaterSetup(data){
    
    wVert = data[0];
    waterIndices = data[1];
    
    

    waterVert = gl.createBuffer();
    waterInd = gl.createBuffer();
    waterNorm = gl.createBuffer();
   
    //for (int i = 0; i < waterIndices.length; i++) {
      //wNorm.add(-1.0);
    //}
/*
    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, waterInd);
    gl.bufferDataTyped(RenderingContext.ELEMENT_ARRAY_BUFFER,
        new Uint16List.fromList(waterIndices), STATIC_DRAW);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, waterVert);
    gl.bufferDataTyped(RenderingContext.ARRAY_BUFFER,
        new Float32List.fromList(wVert), DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, waterNorm);
    gl.bufferData(ARRAY_BUFFER, new Float32List.fromList(wNorm), STATIC_DRAW);
    */
    //ready = true;
  }

  createFlatWater() {
    wVert = new List();
       waterIndices = new List();
     
       waterVert = gl.createBuffer();
       waterInd = gl.createBuffer();
       waterNorm = gl.createBuffer();
       
       for (double i = 0.0; i < X; i++) {
         for (double j = 0.0; j < Y; j++) {
           wVert.add(i * (128 / (X - 1)) + (128 * locX) - (5 * 128));// + (locX*res) - res);
           wVert.add(-0.5);
           wVert.add(j * (128 / (Y - 1)) + (128 * locY) - (5 * 128));// + (locY*res) - res);
         }
       }

       int pos;
       
       for (int i = 0; i < X - 1; i++) {
         for (int j = 0; j < Y - 1; j++) {

           //the possition of the vertic in the indice array we want to draw.
           pos = i * X + j;

           //top half of square
           waterIndices.add(pos);
           waterIndices.add(pos + 1);
           waterIndices.add(pos + X);

           //bottem half of square
           waterIndices.add(pos + X);
           waterIndices.add(pos + X + 1);
           waterIndices.add(pos + 1);
         }
       }
       
       for (int i = 0; i < waterIndices.length; i++) {
         wNorm.add(-1.0);
       }

       gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, waterInd);
       gl.bufferDataTyped(RenderingContext.ELEMENT_ARRAY_BUFFER,
           new Uint16List.fromList(waterIndices), STATIC_DRAW);

       gl.bindBuffer(RenderingContext.ARRAY_BUFFER, waterVert);
       gl.bufferDataTyped(RenderingContext.ARRAY_BUFFER,
           new Float32List.fromList(wVert), DYNAMIC_DRAW);

       gl.bindBuffer(RenderingContext.ARRAY_BUFFER, waterNorm);
       gl.bufferData(
           ARRAY_BUFFER, new Float32List.fromList(wNorm), STATIC_DRAW);
       
       ready = true;
  }
}

/*
 
 createFlatWater(){
   wVert = new List();
   waterIndices = new List();
 
   waterVert = gl.createBuffer();
   waterInd = gl.createBuffer();
   waterNorm = gl.createBuffer();
   
   for (double i = 0.0; i < X; i++) {
     for (double j = 0.0; j < Y; j++) {
       wVert.add(i * (128 / (X - 1)) + (128 * locX) - (5 * 128));// + (locX*res) - res);
       wVert.add(-0.5);
       wVert.add(j * (128 / (Y - 1)) + (128 * locY) - (5 * 128));// + (locY*res) - res);
     }
   }

   int pos;
   
   for (int i = 0; i < X - 1; i++) {
     for (int j = 0; j < Y - 1; j++) {

       //the possition of the vertic in the indice array we want to draw.
       pos = i * X + j;

       //top half of square
       waterIndices.add(pos);
       waterIndices.add(pos + 1);
       waterIndices.add(pos + X);

       //bottem half of square
       waterIndices.add(pos + X);
       waterIndices.add(pos + X + 1);
       waterIndices.add(pos + 1);
     }
   }
   
   for (int i = 0; i < waterIndices.length; i++) {
     wNorm.add(-1.0);
   }

   gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, waterInd);
   gl.bufferDataTyped(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER,
       new Uint16List.fromList(waterIndices), webgl.STATIC_DRAW);

   gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, waterVert);
   gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER,
       new Float32List.fromList(wVert), webgl.DYNAMIC_DRAW);

   gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, waterNorm);
   gl.bufferData(
       webgl.ARRAY_BUFFER, new Float32List.fromList(wNorm), webgl.STATIC_DRAW);
 }*/
