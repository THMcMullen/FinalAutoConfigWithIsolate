library utils;

import 'dart:web_gl' as webgl;

import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';





webgl.Program loadShaderSource(webgl.RenderingContext gl, String vertShaderSource, String fragShaderSource){
  
  webgl.Shader fragShader = gl.createShader(webgl.RenderingContext.FRAGMENT_SHADER);
  webgl.Shader vertShader = gl.createShader(webgl.RenderingContext.VERTEX_SHADER);
  
  //Link Shaders and source code together
  gl.shaderSource(fragShader, fragShaderSource);
  gl.shaderSource(vertShader, vertShaderSource);
  
  gl.compileShader(vertShader);
  gl.compileShader(fragShader);
  
  //Create Shader Program, and link the shaders to it
  webgl.Program shaderProgram = gl.createProgram();
  gl.attachShader(shaderProgram, vertShader);
  gl.attachShader(shaderProgram, fragShader);
  gl.linkProgram(shaderProgram);
  
  //check to make sure the shaders are set up correctly
  if(!gl.getProgramParameter(shaderProgram, webgl.RenderingContext.LINK_STATUS)){
    
    //var s =  gl.deleteProgram(shaderProgram);
    //print("$s shaders failed");
    
  }
    
  //shaders compiled correctly and should be working 
  return shaderProgram;  
  
}

Map<String, int> linkAttributes(webgl.RenderingContext gl, webgl.Program shader, attr){
  Map<String, int> attrib = new Map.fromIterable(attr,
                                key: (item) => item,
                                value: (item) => gl.getAttribLocation(shader, item));
  
  return attrib;
}

Map<String, int> linkUniforms(webgl.RenderingContext gl, webgl.Program shader, uni){
  Map<String, int> uniform = new Map.fromIterable(uni,
                                  key: (item) => item,
                                  value: (item) => gl.getUniformLocation(shader, item));
  
  return uniform;  
}

//remove or replace this, there needs to be a better way
void setMatrixUniforms(webgl.RenderingContext gl, Matrix4 mvMatrix, Matrix4 pMatrix, webgl.UniformLocation pMatrixUniform, webgl.UniformLocation mvMatrixUniform, webgl.UniformLocation nMatrixUniform ){
  Float32List tempMV = new Float32List(16);
  Float32List tempP = new Float32List(16);
  Float32List tempN = new Float32List(9);  
  
  Matrix3 normMatrix = mvMatrix.getRotation();
  
  for(int i = 0; i < 16 ; i++){
    tempMV[i] = mvMatrix[i];
    tempP[i] = pMatrix[i];   
  }
  
  for(int j = 0; j < 9; j++){
    tempN[j] = normMatrix[j];
  }
  
  gl.uniformMatrix4fv(pMatrixUniform, false, tempP);
  gl.uniformMatrix4fv(mvMatrixUniform, false, tempMV);
  gl.uniformMatrix3fv(nMatrixUniform, false, tempN);
  
}


