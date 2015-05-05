library contour_tracing;
//find the edges of the tile
//might link into the waterIso


//takes in a tile, finds where water is located, based on the defined water level
class contour_tracing {
  double level;
    int dir;
    var heightMap;
    var blobMap;
    
    int d;
    int turnTries;
    int counter = 0;

    int workingX;
    int workingY;

    contour_tracing(double waterLevel, var tile) {
      level = waterLevel;
      heightMap = tile;
      
      d = tile.length;

      blobMap = new List(d+2);
      for(int i = 0; i < d+2; i++){
        blobMap[i] = new List(d+2);
        for(int j = 0; j < d+2; j++){
          blobMap[i][j] = 0;
        }
      }
      
      heightMap = new List(d+2);
      for(int i = 0; i < d+2; i++){
        heightMap[i] = new List(d+2);
        for(int j = 0; j < d+2; j++){
          if(i == 0 || i == d+1 || j == 0 || j == d+1){
            heightMap[i][j] = 0;
          }else{
            heightMap[i][j] = tile[j-1][i-1];
          }
        }
      }

      for (int Oy = 0; Oy < d + 2; Oy++) {
        for (int Ox = 0; Ox < d + 2; Ox++) {
          workingY = Oy;
          workingX = Ox;

          if ((heightMap[workingY][workingX] <= -0.5) && (blobMap[workingY][workingX] == 0)) {
            
            counter++;

            blobMap[workingY][workingX] = counter;

            dir = 2;

            do {
              dir = turnLeft(dir);
              turnTries = 0;
              while (move(dir) == false) {
                var Ndir = turnRight(dir);
                turnTries++;
                if (turnTries >= 4) {
                  break;
                }
                dir = Ndir;
              }
              if (turnTries >= 4) {
                break;
              }
              if (move(dir)) {
                moveX(dir);
                moveY(dir);
              }

            } while (workingX != Ox || workingY != Oy);

            //break; //part of a found area, skip to the end of it on this row
          } else if (heightMap[workingY][workingX] <= -0.5 && blobMap[workingY][workingX] != 0) {
            int temp = blobMap[workingY][workingX];
            for (int z = Ox + 1; z < d + 2; z++) {
              //if we are still in the blob and have not found the end of it
              if (blobMap[Oy][z] != temp) {} else {
                //we have found the end of the blob, so skip x to the end part, and update z to get out of this loop

                Ox = z;
              }
            }
          }
        }
      }

      //go through the blobMap, and ladscape to full in each blob
      for (int i = 1; i < d + 1; i++) {
        for (int j = 1; j < d + 1; j++) {
          //check that above and left have the same label, and we fit the water condition
          if (blobMap[i - 1][j] != 0 && heightMap[i][j] <= -0.5) {
            blobMap[i][j] = blobMap[i - 1][j];
          } else if (blobMap[i][j - 1] != 0 && heightMap[i][j] <= -0.5) {
            blobMap[i][j] = blobMap[i][j - 1];
          }
        }
      }

    }

    int turnLeft(var dir) {
      if (dir == 0) {
        dir = 3;
      } else if (dir == 1) {
        dir = 0;
      } else if (dir == 2) {
        dir = 1;
      } else if (dir == 3) {
        dir = 2;
      }
      return dir;
    }

    int turnRight(var dir) {
      if (dir == 0) {
        dir = 1;
      } else if (dir == 1) {
        dir = 2;
      } else if (dir == 2) {
        dir = 3;
      } else if (dir == 3) {
        dir = 0;
      }
      return dir;
    }
    
    bool move(var dir){
        
    bool moving = false;
    
    if(dir == 0){
      if(heightMap[workingY-1][workingX] <= -0.5 && ((blobMap[workingY-1][workingX] == 0) || (blobMap[workingY-1][workingX] == counter))){
        moving = true;
      }
    }else if(dir == 1){
      if(heightMap[workingY][workingX+1] <= -0.5 && ((blobMap[workingY][workingX+1] == 0)|| (blobMap[workingY][workingX+1] == counter))){
        moving = true;
      }
    }else if(dir == 2){
      if(heightMap[workingY+1][workingX] <= -0.5 && ((blobMap[workingY+1][workingX] == 0)|| (blobMap[workingY+1][workingX] == counter))){
        moving = true;
      }
    }else if(dir == 3){
      if(heightMap[workingY][workingX-1] <= -0.5 && ((blobMap[workingY][workingX-1] == 0) || (blobMap[workingY][workingX-1] == counter))){
        moving = true;
      }
    }
    
    return moving;
    
  }
  
  void moveX(dir){
    //right
    if(dir == 1){
      if(heightMap[workingY][workingX+1] <= -0.5){
        workingX = workingX + 1;
        blobMap[workingY][workingX] = counter;
      }
    //left  
    }else if(dir == 3){
      if(heightMap[workingY][workingX-1] <= -0.5){
        workingX = workingX - 1;
        blobMap[workingY][workingX] = counter;
      }
    }
  }
  void moveY(dir){
    //up
    if(dir == 0){
      if(heightMap[workingY-1][workingX] <= -0.5){
        workingY = workingY - 1;
        blobMap[workingY][workingX] = counter;
      }
    //down 
    }else if(dir == 2){
      if(heightMap[workingY+1][workingX] <= -0.5){
        workingY = workingY + 1;
        blobMap[workingY][workingX] = counter;
      }
    }
  }
}