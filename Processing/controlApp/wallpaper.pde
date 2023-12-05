Wallpaper wallpaper;

class Wallpaper {
  boolean renderWallpaper = true;

  PGraphics canvas;

  PShader simplexShader;
  PShader ditherShader;

  PImage ditherMatrix;
  boolean useDither = false;

  Wallpaper() {
    initGraphics();

    simplexShader = loadShader(dataPath("shaders/simplex.frag"));
    simplexShader.set("iResolution", float(width), float(height), 0.0);
    simplexShader.set("iTime", 0.0);

    ditherMatrix = loadImage(dataPath("shaders/ditherMatrix.png"));
    ditherShader = loadShader(dataPath("shaders/bayerMatrixDither.frag"));
    ditherShader.set("iResolution", float(width), float(height), 0.0);

    //ditherShader.set("iChannel0", tex);
    ditherShader.set("iChannel1", ditherMatrix);
    ditherShader.set("gamma", 0.8);
    ditherShader.set("contrast", 0.8);
    ditherShader.set("invert", 0);
  }

  void initGraphics() {
    canvas = createGraphics(width, height, P2D);
  }

  void render() {
    if (!renderWallpaper) {
      background(0);
      return;
    }
    float currentTime = millis()/1000.0;
    simplexShader.set("iTime", currentTime);
    //draw simplex noise to offscreen buffer
    canvas.beginDraw();
    canvas.shader(simplexShader);
    canvas.rect(0, 0, width, height);
    canvas.endDraw();
    if (useDither) {
      ditherShader.set("iChannel0", canvas);

      pushMatrix();
      translate(0, 0, -500);
      shader(ditherShader);
      rect(0, 0, width, height);
      resetShader();
      popMatrix();
    } else {
      //render simplex
      pushMatrix();
      translate(0, 0, -500);
      image(canvas, 0, 0);
      popMatrix();

      //render dither as ADD over it...
      ditherShader.set("iChannel0", canvas);
      blendMode(ADD);
      pushMatrix();
      translate(0, 0, -500);
      shader(ditherShader);
      rect(0, 0, width, height);
      resetShader();
      popMatrix();
      blendMode(BLEND);
    }
  }
}
