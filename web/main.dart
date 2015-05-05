//creates the GL context to be used
//calls the update and draw functions

import 'dart:html';
import 'dart:web_gl';
import 'dart:async';

import 'core.dart';

void main() {
  //Select the canvas as our rneder tatget
  CanvasElement canvas = querySelector("#render-target"); 
  //canvas.requestFullscreen();
  RenderingContext gl = canvas.getContext3d();
  
  var nexus = new core(gl, canvas);
  
  //set up the enviroment
  nexus.setup();
  
  logic(){  
    new Future.delayed(const Duration(milliseconds: 15), logic);
    nexus.update();
  }

  render(time){
    window.requestAnimationFrame(render);
    nexus.draw(); 
  }

  logic();
  render(1);

}
