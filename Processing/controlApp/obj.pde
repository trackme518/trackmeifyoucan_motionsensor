//functions to load 3D models = .obj from data folder and manipulate them
//Pshape OBJ docs: https://github.com/processing/processing/blob/master/core/src/processing/core/PShapeOBJ.java
//PShape: https://github.com/processing/processing/blob/master/core/src/processing/core/PShape.java


//obj.noTexture(); //does not work
//obj.tint(255,0,0); //tint() can only be called between beginShape() and endShape()
//obj.setFill(color(200, 0, 0)); //does not work on textured models
boolean loadedModels = false;
ArrayList<PShapeModel>models = new ArrayList<PShapeModel>();

class PShapeModel {
  PShape obj;
  PShape objNoTex;
  String name;
  String path;
  color pickerColor;

  PShapeModel(String title, String objPath) {
    name = title;
    path = objPath;
    obj = loadShape(objPath);
    obj.setName(name); //save the info about its path nto name field
    //creating true copy of PShape in thread is giving me headaches - let's use alternative shader instead I guess
    //objNoTex = loadShape(objPath);
    //objNoTex = recreateShape(obj); //somehow this is not working either - need fixing
    //objNoTex = obj.getTessellation(); //this was giving error sometimes...
  }

/*
  void setPickerColor(color col) {
    pickerColor = col;
    objNoTex.setFill(pickerColor);
  }
  */
}

int modelIndex = 0; //index of current 3D model to be assigned

PShader tintObjShader = null;
PShader flatFillObjShader = null;

//retrieve all .obj models and load them
void loadModels() {
  //tintObjShader = loadShader(PShader.FLAT, dataPath("shaders/tintFrag.glsl"));
  tintObjShader = loadShader(dataPath("shaders/tintFrag.glsl"));
  tintObjShader.set("col", new PVector(1.0, 1.0, 1.0));
  
  flatFillObjShader = loadShader(dataPath("shaders/flatFillFrag.glsl"));
  flatFillObjShader.set("col", new PVector(1.0, 1.0, 1.0));

  //ArrayList<String>datafilespaths = getPathsFromFiles( loadFiles(dataPath("models"), ".obj") ); //see util tab
  ArrayList<File>datafiles =loadFiles(dataPath("models"), ".obj") ;
  //filelist.get(i).getAbsolutePath()
  println("loaded 3D models: //------------------------");
  for (int i=0; i<datafiles.size(); i++) {
    try {
      String path = datafiles.get(i).getAbsolutePath();
      String parentDirName = datafiles.get(i).getParentFile().getName();
      PShape newmodel = loadShape(path);

      models.add( new PShapeModel( parentDirName, path ) ); //processing will fail to load filename with spaces...ups
      println(parentDirName);
      //But there is yet another issue with OBJ - filenames must absolutely not contain any space.
      //This is simply not supported by the format, and if your mtl and/or texture files have some,
      //they won't get loaded.
    }
    catch(Exception e) {
      println(e);
    }
  }
  println("//-------------------------------------------");
  loadedModels = true;
}
//---------------------------------------------
//automatically assign 3D model from loaded models - ensure unique if possible
PShapeModel getModel() {
  PShapeModel result = null;
  if (models==null || models.size()<1 ) {
    println("no 3D models loaded");
    return null;
  }
  if (modelIndex>models.size()-1) {
    modelIndex = 0;
  }
  result = models.get(modelIndex);
  modelIndex++;
  return result;
}
//-------------------------------------
//recreate new model from loaded .obj model in native PShape format to enable texture manipulation
PShape recreateShape(PShape parent) {
  /*
  //PImage tex = parent.image; //not visible - :-(
   if (cloneTexture) {
   PImage tex = null;
   try {
   String texturePath = parent.getName().substring(0, parent.getName().length()-3)+".png";
   tex = loadImage(texturePath);
   }
   catch(Exception e) {
   println(e);
   }
   }
   */
  // Make a group PShape
  PShape groupShape = createShape(GROUP);
  //PShape[] faces = new PShape[parent.getChildCount()];
  println("children: "+parent.getChildCount());
  for (int i = 0; i < parent.getChildCount(); i++) {
    PShape face = parent.getChild(i);
    PShape d = copyShape(face);
    groupShape.addChild(d);
  }
  return groupShape;
}

PShape copyShape(PShape original) {

  PShape copy_shape = createShape();
  int nOfVertexes = original.getVertexCount();
  int nOfVertexesCodes = original.getVertexCodeCount();
  int code_index = 0; // which vertex i'm reading?
  PVector pos[] = new PVector[nOfVertexes];
  int codes[] = new int[nOfVertexes];

  println("nOfVertexes: "+nOfVertexes);
  println("nOfVertexesCodes: "+nOfVertexesCodes);

  // creates the shape to be manipulated
  // and initiate the codes array
  beginShape();
  for (int i=0; i< nOfVertexes; i++) {
    copy_shape.vertex(0, 0);
    codes[i] = 666; //random number, different than 0 or 1
  }
  endShape();

  // GET THE CODES
  for (int i=0; i< nOfVertexesCodes; i++) {
    int code = original.getVertexCode(i);
    codes[code_index] = code;
    if (code == 0) {
      code_index++;
    } else if ( code == 1) {
      code_index +=3;
    }
  }
  // GET THE POSITIONS
  for (int i=0; i< nOfVertexes; i++) {
    pos[i] = original.getVertex(i);
  }
  //for debugging purposes
  println("==============POS==============");
  printArray(pos);
  println("==============CODES==============");
  printArray(codes);

  copy_shape = createShape();
  copy_shape.beginShape();
  for (int i=0; i< nOfVertexes; i++) {
    if ( codes[i] == 0) {
      //if a regular vertex
      copy_shape.vertex(pos[i].x, pos[i].y);
    } else if ( codes[i]==1 ) {
      //if a bezier vertex
      copy_shape.bezierVertex(pos[i].x, pos[i].y,
        pos[i+1].x, pos[i+1].y,
        pos[i+2].x, pos[i+2].y);
    } else {
      //this vertex will be used inside the bezierVertex, wich uses 3 vertexes at once
      println("skipping vertex "+i);
    }
  }
  copy_shape.endShape();
  return copy_shape;
}
