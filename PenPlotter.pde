import processing.core.*;
import processing.event.*;

import controlP5.*;
import geomerative.*;
import processing.serial.*;
import java.util.Properties;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.BufferedWriter;
import java.io.FileWriter;
import javax.swing.SwingUtilities;
import javax.swing.JFileChooser;
import java.util.Map;
import java.util.Collections;
import java.util.Enumeration;
import java.util.Vector;
import toxi.geom.*;
import toxi.geom.mesh2d.*;
import toxi.processing.*;
import java.util.ArrayList;
import java.io.File;
import javax.swing.filechooser.FileFilter;
import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeEvent;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;

import java.awt.event.ActionEvent;
import java.awt.event.WindowEvent;
import java.awt.event.ActionListener;
import java.awt.event.WindowListener;
import java.awt.event.WindowAdapter;
import javax.swing.*;
import java.util.logging.*;
import java.text.*;
import java.util.*;
import java.io.*;
import java.awt.Dimension;
import java.awt.Toolkit;
import java.awt.BorderLayout;

import codeanticode.tablet.*;

// import http.requests.*;

import websockets.*;
WebsocketServer ws;

// WebsocketClient wsc;

Tablet tablet;

boolean tabletMode = false;
boolean pmousePressed = false;

// import spacebrew.*;


// String server = "localhost";
String server = "sandbox.spacebrew.cc";
String name = "Tipibot";
String description = "Tipibot commands.";


// Connection to outer world
// Spacebrew sb;
JSONObject json;

final static String ICON  = "icons/penDown.png";
final static String TITLE = "PenPlotter v0.8";

ControlP5 cp5;
Handle[] handles;
float cncSafeHeight = 5;  // safe height for cnc export
float flipX = 1;          // mirror around X if set to -1
float flipY = 1;          // mirror around Y if set to -1
float scaleX = 1;         // combined scale svgScale*userScale*flipX
float scaleY = 1;         // combined scale svgScale*userScale*flipY
float userScale = 1;      // user controlled scale from slider


int jogX;                 // set if jog X button pressed
int jogY;                 // set if jog Y button pressed

int machineWidth = 840;   // Width of machine in mm
int homeX = machineWidth / 2; //X Home position
int machineHeight = 800;    //machine Height only used to draw page height
int homeY = 250;          // location of homeY good location is where gondola hangs with motor power off
int homeOffsetY = 2250;

float currentX = homeX;   // X location of gondola
float currentY = homeY;   // X location of gondola

float previousX = 0;
float previousY = 0;

int tabletX = 0;
int tabletY = 0;
int tabletWidth = width;
int tabletHeight = height;
int tabletMarginX = 0;
int tabletMarginY = 0;

int speedValue = 20000;     // speed of motors controlled with speed slider
int delay = 0;              // delay between two segments/curves (0 = no delay)

float stepsPerRev = 6400; // number of steps per rev includes microsteps
float mmPerRev = 80;      // mm per rev

float zoomScale = 0.75f;   // screen scale controlle with mouse wheel
float shortestSegment = 0;    // cull out svg segments shorter that is.


int menuWidth = 140;
int originX = (machineWidth + menuWidth) / 2; // screen X offset of page will change if page dragged
int originY = 200;                        // screen Y offset of page will change if page dragged

int oldOriginX;          // old location page when drag starts
int oldOriginY;
int oldOffX;             // old offset when right drag starts
int oldOffY;

int offX = 0;            // offset of drawing from origin, used everywhere to offset the plot and drawing
int offY = 0;
int offXTopLeft = 0;     // offset input from top left, used as offX input, defined from topLeft, not from center

int startX;              // start location of mouse drag
int startY;

int imageX = 160;        // location to draw image overlay
int imageY = 10;

int imageWidth = 200;   // size of image overlay
int imageHeight = 200;

int cropLeft = imageX;
int cropTop = imageY;
int cropRight = imageX + imageWidth;
int cropBottom = imageY + imageHeight;

String currentFileName = "";

boolean overLeft = false;
boolean overRight = false;
boolean overTop = false;
boolean overBottom = false;
boolean motorsOn = false;

boolean fastMode = false;


int pageColor = color(255, 255, 255);
int machineColor = color(250, 250, 250);
int backgroundColor = color(192, 192, 192);
int gridColor = color(128, 128, 128);
int cropColor = color(0, 255, 0);
int textColor = color(113, 113, 113);
int gondolaColor = color(0, 0, 0, 128);
int statusColor = color(0, 0, 0);
int motorOnColor = color(239, 136, 93);
int motorOffColor = color(44, 175, 161);

int penColor = color(0, 0, 0, 255);
int previewColor = color(0, 0, 0, 255);
int whilePlottingColor = color(0, 0, 0, 64);
int rapidColor = color(0, 255, 0, 64);

int buttonPressColor = color(195, 241, 236);
int buttonHoverColor = color(239, 136, 93);
int buttonUpColor = color(44, 175, 161);
int buttonTextColor = color(0, 0, 0);
int buttonBorderColor = color(0, 0, 0);

Plot currentPlot = new Plot();
float lastX = 0;
float lastY = 0;

PApplet applet = this;
PImage simage;
PImage oimg;
StipplePlot stipplePlot = new StipplePlot();
DiamondPlot diamondPlot = new DiamondPlot();
HatchPlot hatchPlot = new HatchPlot();
SquarePlot squarePlot = new SquarePlot();
float svgDpi = 72;
float svgScale = 25.4f / svgDpi;

float penWidth = 0.5f;
int pixelSize = 8;
int range = 255 / (int) ((float) (pixelSize) / penWidth);

int HATCH = 0;
int DIAMOND = 1;
int SQUARE = 2;
int STIPPLE = 3;
int imageMode = HATCH;
long lastTime = millis();
long freeMemory;
long totalMemory;
int servoDwell = 0;
int servoUpValue = 1700;
int servoDownValue = 1400;
int servoUpTempo = 0;
int servoDownTempo = 1000;
int rate;
int tick;

int seconds = 0;

float paperWidth = 8.5;
float paperHeight = 11;
public static Console console;
Com com = new Com();
boolean settingPenPosition = false;
boolean setPenPositionButtonJustPressed = false;

int rotation = 0;
int symmetry = 0;


FloatList tabletQueue = new FloatList();
FloatList tabletDrawing = new FloatList();

float tabletLength = 0.f;
float maxTabletLength = 200.f;

PrintWriter gpsCoordsFileWriter;

boolean isDrawing = false;

private void prepareExitHandler () {

    Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {

        public void run() {
            println("SHUTDOWN HOOK");
        }
    }
                                                   ));
}

public void exit() {
    println("exit");
    com.sendMotorOff();
    delay(1000);
    super.exit();
}

public void changeAppIcon(PImage img) {
    final PGraphics pg = createGraphics(16, 16, JAVA2D);

    pg.beginDraw();
    pg.image(img, 0, 0, 16, 16);
    pg.endDraw();
    frame.setIconImage(pg.image);
}

public void changeAppTitle(String title) {
    //surface.setTitle(title);
    surface.setTitle(title);
}

public void settings() {
    size(1280, 800, JAVA2D);
}

public void setup() {
    gpsCoordsFileWriter = createWriter("gpsCoords.txt");

    ws = new WebsocketServer(this,8025,"/tipibot");
    // wsc = new WebsocketClient(this, "ws://localhost:8000/socket.io/1/websocket/45340132079");

    String he = "FF8AC443";

    println("a color: " + color(0, 128, 255, 50));

    println("a color:r " + red(color(0, 128, 255, 50)));
    println("a color:g " + green(color(0, 128, 255, 50)));
    println("a color:b " + blue(color(0, 128, 255, 50)));
    println("a color:a " + alpha(color(0, 128, 255, 50)));

    println("a color:r " + red(unhex(he)));
    println("a color:g " + green(unhex(he)));
    println("a color:b " + blue(unhex(he)));
    println("a color:a " + alpha(unhex(he)));

    println("a color: " + unhex(he));


    tablet = new Tablet(this);

    // // Spacebrew communication:

    // // instantiate the spacebrewConnection variable
    // sb = new Spacebrew( this );

    // // declare your publishers
    // // sb.addPublish( "local_slider", "range", local_slider_val );
    // // sb.addPublish( "button_pressed", "boolean", true);

    // // declare your subscribers
    // sb.addSubscribe( "commands", "string" );
    // sb.addSubscribe( "command", "string" );

    // // connect!
    // sb.connect(server, name, description);


    //surface.setResizable(true);
    surface.setResizable(true);
    changeAppIcon( loadImage(ICON) );
    changeAppTitle(TITLE);
    prepareExitHandler();


    getProperties();

    tabletX = Integer.parseInt(props.getProperty("tablet.x"));
    tabletX = tabletX < 0 ? 0 : tabletX;

    tabletY = Integer.parseInt(props.getProperty("tablet.y"));
    tabletY = tabletY < 0 ? 0 : tabletY;
    tabletWidth = Integer.parseInt(props.getProperty("tablet.width"));
    tabletWidth = tabletWidth < 0 ? 0 : width;
    tabletHeight = Integer.parseInt(props.getProperty("tablet.height"));
    tabletWidth = tabletHeight < 0 ? 0 : height;

    tabletMarginX = Integer.parseInt(props.getProperty("tablet.margin.x"));
    tabletMarginY = Integer.parseInt(props.getProperty("tablet.margin.y"));

    machineWidth = Integer.parseInt(props.getProperty("machine.width"));
    machineHeight = Integer.parseInt(props.getProperty("machine.height"));
    homeX = machineWidth / 2;

    homeY = Integer.parseInt(props.getProperty("machine.homepoint.y"));
    homeOffsetY = Integer.parseInt(props.getProperty("machine.homepoint.offsety"));
    mmPerRev = Float.parseFloat(props.getProperty("machine.motors.mmPerRev"));
    stepsPerRev = Float.parseFloat(props.getProperty("machine.motors.stepsPerRev"));

    currentX = homeX;
    currentY = homeY + homeOffsetY;

    penWidth = Float.parseFloat(props.getProperty("machine.penSize"));

    svgDpi = Float.parseFloat(props.getProperty("svg.pixelsPerInch"));
    svgScale = 25.4f / svgDpi;

    currentFileName = props.getProperty("svg.name");

    cncSafeHeight = Float.parseFloat(props.getProperty("cnc.safeHeight"));


    com.baudRate = Long.parseLong(props.getProperty("com.baudrate"));
    //todo lastPort not used

    com.lastPort = Integer.parseInt(props.getProperty("com.serialPort"));

    zoomScale = Float.parseFloat(props.getProperty("machine.zoomScale"));

    cropLeft = Integer.parseInt(props.getProperty("image.cropLeft"));
    if (cropLeft < imageX) cropLeft = imageX;
    cropRight = Integer.parseInt(props.getProperty("image.cropRight"));
    if (cropRight > imageX + imageWidth) cropRight = imageX + imageWidth;
    cropTop = Integer.parseInt(props.getProperty("image.cropTop"));
    if (cropTop < imageY) cropTop = imageY;
    cropBottom = Integer.parseInt(props.getProperty("image.cropBottom"));
    if (cropBottom > imageY + imageHeight) cropBottom = imageY + imageHeight;

    paperWidth = Float.parseFloat(props.getProperty("paper.width")) / 25.4;
    paperHeight = Float.parseFloat(props.getProperty("paper.height")) / 25.4;

    offXTopLeft = Integer.parseInt(props.getProperty("machine.offX"));
    offY = Integer.parseInt(props.getProperty("machine.offY"));

    offX = - int(paperWidth * 25.4f / 2.f) + offXTopLeft;

    shortestSegment = Float.parseFloat(props.getProperty("svg.shortestSegment"));

    servoUpValue = Integer.parseInt(props.getProperty("servo.angle.up"));
    servoDownValue = Integer.parseInt(props.getProperty("servo.angle.down"));

    servoUpTempo = Integer.parseInt(props.getProperty("servo.tempo.up"));
    servoDownTempo = Integer.parseInt(props.getProperty("servo.tempo.down"));

    com.listPorts();

    RG.init(this);
    RG.ignoreStyles(true);
    RG.setPolygonizer(RG.ADAPTATIVE);

    createcp5GUI();

    speedValue = Integer.parseInt(props.getProperty("machine.motors.maxSpeed"));
    speedSlider.setValue(speedValue);

    delay = Integer.parseInt(props.getProperty("machine.delay"));
    delaySlider.setValue(delay);

    pixelSize = Integer.parseInt(props.getProperty("image.pixelSize"));
    pixelSizeSlider.setValue(pixelSize);

    userScale = Float.parseFloat(props.getProperty("svg.UserScale"));
    scaleSlider.setValue(userScale);



    updateScale();

    handles = new Handle[6];
    handles[0] = new Handle("homeY", 0, homeY, 0, 10, handles, false, true, 128);
    handles[1] = new Handle("mWidth", machineWidth, machineHeight / 2, 0, 10, handles, true, false, 64);
    handles[2] = new Handle("mHeight", homeX, machineHeight, 0, 10, handles, false, true, 64);
    handles[3] = new Handle("gondola", (int)currentX, (int)currentY, 0, 10, handles, true, true, 2);
    handles[4] = new Handle("pWidth", Math.round(homeX + (paperWidth / 2) * 25.4), Math.round(homeY + (paperHeight / 2) * 25.4f), 0, 10, handles, true, false, 64);
    handles[5] = new Handle("pHeight", homeX, Math.round(homeY + (paperHeight) * 25.4), 0, 10, handles, false, true, 64);
}

public void mousePressed() {
    if (tabletMode) {
        return;
    }
    startX = mouseX;
    startY = mouseY;
    oldOriginX = originX;
    oldOriginY = originY;
    oldOffX = offXTopLeft;
    oldOffY = offY;

    previousX = currentX;
    previousY = currentY;
}

public void mouseDragged() {
    if (tabletMode) {
        return;
    }
    if (mouseButton == CENTER) {
        originX = oldOriginX + mouseX - startX;
        originY = oldOriginY + mouseY - startY;
    } else if (mouseButton == RIGHT) {
        offXTopLeft = oldOffX + (int)((mouseX - startX) / zoomScale);
        offY = oldOffY + (int)((mouseY - startY) / zoomScale);

        offsetXSlider.setValue(Math.min(Math.max(0, offXTopLeft), paperWidth * 25.4f));
        offsetYSlider.setValue(Math.min(Math.max(0, offY), paperHeight * 25.4f));

        offX = - int(paperWidth * 25.4f / 2.f) + offXTopLeft;
    }
}

public void mouseReleased() {

    if (tabletMode) {
        return;
    }

    if (overLeft || overRight || overTop || overBottom) {
        currentPlot.crop(cropLeft, cropTop, cropRight, cropBottom);
    }
    overLeft = false;
    overRight = false;
    overTop = false;
    overBottom = false;
    startX = 0;
    startY = 0;

    for (Handle handle : handles) {
        if (handle.wasActive()) {
            if (handle.id.equals("gondola") && !settingPenPosition) {
                float newX = currentX;
                float newY = currentY;
                currentX = previousX;
                currentY = previousY;
                com.sendMoveG0(newX, newY);
            }
            if (handle.id.equals("homeY")) {
                com.sendHome();
            }
            if (handle.id.equals("mWidth")) {
                com.sendSpecs();
            }
        }
        handle.releaseEvent();
    }

    if (settingPenPosition && !setPenPositionButtonJustPressed) {
        setPenPositionButton.setCaptionLabel("Set pen position");
        settingPenPosition = false;
        com.sendSetPositionG92(Math.round((mouseX - scaleX(0)) / zoomScale), Math.round((mouseY - scaleY(0)) / zoomScale));
    }
    if (setPenPositionButtonJustPressed) {
        setPenPositionButtonJustPressed = false;
    }
}

public void mouseWheel(MouseEvent event) {

    float e = event.getCount();

    if (e > 0)
        setZoom(zoomScale += 0.1f);
    else if (zoomScale > 0.1f)
        setZoom(zoomScale -= 0.1f);
}



public void keyPressed() {

    if (key == CODED) {
        if (keyCode == UP) {
            servoDownValue += 10;
            servoDownSlider.setValue(servoDownValue);
        } else if (keyCode == DOWN) {
            servoDownValue -= 10;
            servoDownSlider.setValue(servoDownValue);
        }
        if (keyCode == RIGHT) {
            servoUpValue += 10;
            servoUpSlider.setValue(servoUpValue);
        } else if (keyCode == LEFT) {
            servoUpValue -= 10;
            servoUpSlider.setValue(servoUpValue);
        }
    }

    if (key == 'x') {
        flipX *= -1;
        updateScale();
    } else if (key == 'y') {
        flipY *= -1;
        updateScale();
    }

    if (key == 'c') {
        println("control");
        initLogging();
    }

    if (key == 't') {
        tabletMode = !tabletMode;
        println("Set tabletMode to: " + tabletMode);
        if(tabletMode) {
            tabletModeButton.setCaptionLabel("Normal mode");
        } else {
            tabletModeButton.setCaptionLabel("Tablet mode");
        }


    }

    if(key == 'w') {
        gpsCoordsFileWriter.flush();
    }
}
void initLogging() {
    try {
        console = new Console();
    } catch (Exception e) {
        println("Exception setting up logger: " + e.getMessage());
    }
}
public void handleMoved(String id, int x, int y) {
    if (tabletMode) {
        return;
    }
    if (id.equals("homeY"))
        homeY = y;
    else if (id.equals("gondola")) {

        currentX = x;
        currentY = y;
    } else if (id.equals("mWidth")) {
        machineWidth = x;
        homeX = machineWidth / 2;
        handles[2].x = homeX;
        //makeHatchImage();

    } else if (id.equals("mHeight")) {
        machineHeight = y;
        handles[1].y = y / 2;
        // makeHatchImage();
    } else if (id.equals("pWidth")) {
        paperWidth = (x - homeX) * 2 / 25.4;
    } else if (id.equals("pHeight")) {
        paperHeight = (y - homeY) / 25.4;
    }
}

public boolean overCropLeft(int x, int y) {
    if (overLeft) return true;

    int x1 = cropLeft;
    int x2 = x1 + 10;
    int y1 = cropTop + (cropBottom - cropTop) / 2 - 5;
    int y2 = y1 + 10;

    if (x < x1) return false;
    if (x > x2) return false;
    if (y < y1) return false;
    if (y > y2) return false;

    overLeft = true;
    return true;
}

public boolean overCropRight(int x, int y) {
    if (overRight) return true;

    int x1 = cropRight - 10;
    int x2 = x1 + 10;
    int y1 = cropTop + (cropBottom - cropTop) / 2 - 5;
    int y2 = y1 + 10;

    if (x < x1) return false;
    if (x > x2) return false;
    if (y < y1) return false;
    if (y > y2) return false;

    overRight = true;
    return true;
}

public boolean overCropTop(int x, int y) {
    if (overTop) return true;

    int x1 = cropLeft + (cropRight - cropLeft) / 2 - 5;
    int x2 = x1 + 10;
    int y1 = cropTop;
    int y2 = y1 + 10;

    if (x < x1) return false;
    if (x > x2) return false;
    if (y < y1) return false;
    if (y > y2) return false;

    overTop = true;
    return true;
}

public boolean overCropBottom(int x, int y) {
    if (overBottom) return true;

    int x1 = cropLeft + (cropRight - cropLeft) / 2 - 5;
    int x2 = x1 + 10;
    int y1 = cropBottom - 10;
    int y2 = y1 + 10;

    if (x < x1) return false;
    if (x > x2) return false;
    if (y < y1) return false;
    if (y > y2) return false;

    overBottom = true;
    return true;
}

public void setSpeed(int value) {
    speedValue = value;
    com.sendSpeed(speedValue);
}

public void setuserScale(float value) {
    userScale = value;
    updateScale();
    setImageScale();
}

public void updateScale() {
    scaleX = svgScale * userScale * flipX;
    scaleY = svgScale * userScale * flipY;
}

public void setImageScale() {
    currentPlot.crop(cropLeft, cropTop, cropRight, cropBottom);
}

public void setZoom(float value) {
    zoomScale = value;
}

public void setPenWidth(float width) {
    penWidth = width;
    com.sendPenWidth();

    if (!currentPlot.isPlotting()) {
        int levels = (int) ((float) (pixelSize) / penWidth);
        if (levels < 1) levels = 1;
        if (levels > 255) levels = 255;
        range = 255 / levels;

        currentPlot.calculate();
    }
}

public void setPixelSize(int value) {

    if (!currentPlot.isPlotting()) {
        pixelSize = value;

        int levels = (int) ((float) (pixelSize) / penWidth);
        if (levels < 1) levels = 1;
        if (levels > 255) levels = 255;
        range = 255 / levels;

        currentPlot.calculate();

    }
}

public float unScaleX(float x) {
    return (x - originX) / zoomScale + homeX;
}

public float unScaleY(float y) {
    return (y - originY) / zoomScale + homeY;
}

public float scaleX(float x) {
    return (x - homeX) * zoomScale + originX;
}

public float scaleY(float y) {
    return (y - homeY) * zoomScale + originY;
}

public void updatePos(float x, float y) {
    currentX = x;
    currentY = y;
    handles[3].x = x;
    handles[3].y = y;
    motorsOn = true;
}

public void sline(float x1, float y1, float x2, float y2) {
    strokeWeight(0.5f);
    line(scaleX(x1), scaleY(y1), scaleX(x2), scaleY(y2));
}

public void computeRotations(float cx, float cy) {

    double angleStep = 2.f * Math.PI / (rotation + 1.f);
    double angle = angleStep;

    for(int r = 0 ; r < rotation ; r++) {

        for(int i = 0 ; i < tabletQueue.size() ; i+=2) {

            float x = tabletQueue.get(i);
            float y = tabletQueue.get(i+1);

            float vx = x - cx;
            float vy = y - cy;

            double nx = vx * Math.cos(angle) - vy * Math.sin(angle);
            double ny = vx * Math.sin(angle) + vy * Math.cos(angle);

            float rx = (float)(cx + nx);
            float ry = (float)(cy + ny);

            tabletDrawing.append(scaleX(rx));
            tabletDrawing.append(scaleY(ry));

            if(i == 0) {
                com.sendMoveG0(rx, ry);
                com.sendPenDown();
            }
            else {
                com.sendMoveG1(rx, ry);
            }

            if(i == tabletQueue.size() - 2) {
                com.sendPenUp();
                tabletDrawing.append(-1.f);
                tabletDrawing.append(-1.f);
            }
        }

        angle += angleStep;
    }
}

public void computeSymmetry(float cx, float cy, boolean horizontal, boolean vertical, boolean invert, FloatList totalTabletQueue) {

    FloatList copy = totalTabletQueue.copy();
    for(int i = 0 ; i < copy.size() ; i+=2) {

        float x = copy.get(i);
        float y = copy.get(i+1);

        if(x < 0.f || y < 0.f) {
            totalTabletQueue.append(x);
            totalTabletQueue.append(y);
            continue;
        }

        float vx = x - cx;
        float vy = y - cy;

        float nx = horizontal ? -vx : vx;
        float ny = vertical ? -vy : vy;

        if(invert) {
            float temp = nx;
            nx = ny;
            ny = temp;
        }

        float rx = cx + nx;
        float ry = cy + ny;

        totalTabletQueue.append(rx);
        totalTabletQueue.append(ry);
    }

    totalTabletQueue.append(-1.f);
    totalTabletQueue.append(-1.f);
}

public void computeSymmetries(float cx, float cy) {
    if(symmetry == 0) {
        return;
    }

    FloatList totalTabletQueue = new FloatList();

    totalTabletQueue.append(-1.f);
    totalTabletQueue.append(-1.f);

    for(int i = 0 ; i < tabletQueue.size() ; i++) {
        totalTabletQueue.append(tabletQueue.get(i));
    }


    if(symmetry == 1) {
        computeSymmetry(cx, cy, false, true, false, totalTabletQueue);
    }
    else if(symmetry == 2) {
        computeSymmetry(cx, cy, true, false, false, totalTabletQueue);
    }
    else if(symmetry == 3) {
        computeSymmetry(cx, cy, true, true, false, totalTabletQueue);
    }
    else if(symmetry == 3) {
        computeSymmetry(cx, cy, false, false, true, totalTabletQueue);
    }
    else if(symmetry == 4) {
        computeSymmetry(cx, cy, false, true, false, totalTabletQueue);
        computeSymmetry(cx, cy, true, false, false, totalTabletQueue);
    }
    else if(symmetry == 5) {
        computeSymmetry(cx, cy, true, true, false, totalTabletQueue);
        computeSymmetry(cx, cy, false, false, true, totalTabletQueue);
    }
    else if(symmetry >= 6) {
        computeSymmetry(cx, cy, false, true, false, totalTabletQueue);
        computeSymmetry(cx, cy, true, false, false, totalTabletQueue);
        computeSymmetry(cx, cy, true, true, false, totalTabletQueue);
        computeSymmetry(cx, cy, false, false, true, totalTabletQueue);
    }

    boolean penUp = true;
    for(int i = 0 ; i < totalTabletQueue.size() ; i+=2) {

        float x = totalTabletQueue.get(i);
        float y = totalTabletQueue.get(i+1);


        if(x < 0.f || y < 0.f) {

            tabletDrawing.append(x);
            tabletDrawing.append(y);

            if(!penUp) {
                penUp = true;
                com.sendPenUp();
            }
        }
        else {

            tabletDrawing.append(scaleX(x));
            tabletDrawing.append(scaleY(y));

            if(penUp) {
                penUp = false;
                com.sendMoveG0(x, y);
                com.sendPenDown();
            } else {
                com.sendMoveG1(x, y);
            }
        }
    }

}

// boolean  drawingRequestSent = false;

public RPoint pointFromObject(JSONObject point) {
    return new RPoint(point.getFloat("x"), point.getFloat("y"));
}

public RPoint posOnPlanetToProject(RPoint point, RPoint planet) {
    float x = planet.x * 360 + point.x;
    float y = planet.y * 180 + point.y;
    x *= 1000;
    y *= 1000;
    return new RPoint(x,y);
}

public void createPath(JSONArray points, RPoint planet, RShape shape) {
    RPoint point = pointFromObject(points.getJSONObject(0));
    RPoint handleIn = pointFromObject(points.getJSONObject(1));
    handleIn.add(point);
    RPoint handleOut = pointFromObject(points.getJSONObject(2));
    handleOut.add(point);
    shape.addMoveTo(point);
    for(int i=1; i<points.size() ; i+=4) {
        point = posOnPlanetToProject(pointFromObject(points.getJSONObject(i)), planet);
        handleIn = pointFromObject(points.getJSONObject(i+1));
        handleIn.add(point);
        shape.addBezierTo(handleOut, handleIn, point);
        handleOut = pointFromObject(points.getJSONObject(i+2));
        handleOut.add(point);
    }
}

// public void webSocketEvent(String msg) {
//     println("webSocketEvent:");
//     println(msg);
//     // getNextValidatedDrawing(msg);
// }

public void requestNextDrawing() {
    println("requestNextDrawing...");
    JSONObject params = new JSONObject();
    params.setString("type", "getNextValidatedDrawing");
    ws.sendMessage(params.toString());
    // drawingRequestSent = true;
}

public void setDrawingStatusDrawn(String pk) {
    JSONObject params = new JSONObject();
    params.setString("type", "setDrawingStatusDrawn");
    params.setString("pk", pk);
    ws.sendMessage(params.toString());
}


// public void getNextValidatedDrawing(String result) {
    
//     // PostRequest post = new PostRequest("http://localhost:8000/ajaxCallNoCSRF/");
//     // post.addHeader("X-Requested-With", "XMLHttpRequest");
//     // post.addHeader("Content-Type", "application/json");

//     // JSONObject params = new JSONObject();
//     // JSONObject data = new JSONObject();
//     // data.setString("function", "getNextValidatedDrawing");
//     // JSONArray args = new JSONArray();
//     // data.setJSONArray("args", args);
//     // params.setJSONObject("data", data);

//     // post.addJson(params.toString());
//     // // post.addData("name", "Rune");
//     // post.send();
//     // System.out.println("Reponse Content: " + post.getContent());
//     // System.out.println("Reponse Content-Length Header: " + post.getHeader("Content-Length"));

//     JSONObject response = parseJSONObject(result);
//     println("status: " + response.getString("state") + ", pk: " + response.getString("pk"));

//     JSONArray paths = response.getJSONArray("paths");
//     println("paths: ");
//     for(int i=0; i<paths.size() ; i++) {
//         JSONObject path = paths.getJSONObject(i);
//         JSONObject pathData = path.getJSONObject("data");
//         RShape shape = new RShape();
//         createPath(pathData.getJSONArray("points"), pointFromObject(pathData.getJSONObject("planet")), shape);

//         shape.setStroke(color(0, 128, 255, 50));
//         shape.setStrokeWeight(10);
//     }
// }

public void draw() {

    int s = second();  // Values from 0 - 59
    
    if(s - seconds > 0 && !isDrawing) {
        // data: JSON.stringify { function: 'savePath', args: args } 
        requestNextDrawing();
        // wsc.sendMessage("\"{\"name\":\"getNextValidatedDrawing\",\"args\":[]}\"");
        // wsc.sendMessage("\"{\"name\":\"setDrawingStatusDrawn\",\"args\":[\"" + pk + "\"]}\"");

        // setDrawingStatusDrawn(request, pk, secret)
    }

    seconds = s;

    background(backgroundColor);

    drawPage();
    drawOrigin();
    drawTicks();
    drawPaper();

    if (!tabletMode) {
        for (Handle handle : handles) {
            handle.update();
            handle.display();
        }
    }

    if (currentPlot.isLoaded()) {
        currentPlot.draw();
    }

    drawGondola();

    if (oimg != null) {
        image(oimg, imageX, imageY, imageWidth, imageHeight);
        drawImageFrame();
        drawSelector();
    }

    if (jogX != 0) {
        com.moveDeltaX(jogX);
    }
    if (jogY != 0) {
        com.moveDeltaY(jogY);
    }
    com.serialEvent();
    tick++;
    if (millis() > lastTime + 1000) {
        rate = tick;
        tick = 0;
        freeMemory = Runtime.getRuntime().freeMemory() / 1000000;
        totalMemory = Runtime.getRuntime().totalMemory() / 1000000;
        lastTime = millis();
    }
    stroke(statusColor);
    fill(statusColor);
    text("FPS: " + nf(rate, 2, 0) + "  Mem: " + freeMemory + "/" + totalMemory + "M", 10, height - 4);
    String status = " Size: " + machineWidth + "x" + machineHeight + " Zoom: " + nf(zoomScale, 0, 2);
    status += " X: " + nf(currentX, 0, 2) + " Y: " + nf(currentY, 0, 2);
    status += " A: " + nf(getMachineA(currentX, currentY), 0, 2);
    status += " B: " + nf(getMachineB(currentX, currentY), 0, 2);
    if (currentPlot.isLoaded())
        status += " Plot: " + currentPlot.progress();
    text(status, 150, height - 4);


    if (tabletMode) {

        stroke(color(238, 65, 97));
        noFill();
        strokeWeight(1);
        rect(tabletX, tabletY, tabletWidth, tabletHeight);

        int drawingMargin = 150;
        stroke(color(38, 65, 237));
        rect(tabletX + drawingMargin, tabletY + drawingMargin, tabletWidth - 2 * drawingMargin, tabletHeight - 2 * drawingMargin);

        float pWidth = paperWidth * 25.4f;
        float pHeight = paperHeight * 25.4f;

        float machineX = homeX - pWidth / 2; // scaleX(0);
        float machineY = homeY;// scaleY(0);

        float tx = ( ( pWidth - 2 * tabletMarginX ) * ( mouseX - tabletX ) / tabletWidth ) + machineX + tabletMarginX;
        float ty = ( ( pHeight - 2 * tabletMarginY ) * ( mouseY - tabletY ) / tabletHeight ) + machineY + tabletMarginY;

        // float drawingMargin = 0.0f;
        // float marginSize = pWidth * drawingMargin / 2.0f;

        // float oneMinusDrawinMargin = 1.0f - drawingMargin;

        // tx = tx * oneMinusDrawinMargin + marginSize;
        // ty = ty * oneMinusDrawinMargin + marginSize;

        // draw tablet lines

        if (mousePressed && !pmousePressed) {
            tabletLength = 0;

            tabletQueue.append(tx);
            tabletQueue.append(ty);
            tabletDrawing.clear();
            tabletDrawing.append(scaleX(tx));
            tabletDrawing.append(scaleY(ty));
            com.sendMoveG0(tx, ty);
            com.sendPenDown();
        } else if (mousePressed && pmousePressed) {

            float dx = tx - tabletQueue.get(tabletQueue.size()-2);
            float dy = ty - tabletQueue.get(tabletQueue.size()-1);

            tabletLength += Math.sqrt( dx * dx + dy * dy);
            println("tabletLength: "+tabletLength);
            if(tabletLength < maxTabletLength) {
                tabletQueue.append(tx);
                tabletQueue.append(ty);
                tabletDrawing.append(scaleX(tx));
                tabletDrawing.append(scaleY(ty));
                com.sendMoveG1(tx, ty);
            }

        } else if (!mousePressed && pmousePressed) {
            com.sendPenUp();
            tabletDrawing.append(-1.f);
            tabletDrawing.append(-1.f);

            float cx = machineX + pWidth / 2.f;
            float cy = machineY + pHeight / 2.f;
            computeRotations(cx, cy);
            computeSymmetries(cx, cy);

            tabletQueue.clear();
        }

        // draw tablet
        if(tabletDrawing.size() >= 4) {
            stroke(color(40, 190, 128));
            strokeWeight(1);
            float px = tabletDrawing.get(0);
            float py = tabletDrawing.get(1);
            float fx = px;
            float fy = py;
            for(int i = 2 ; i < tabletDrawing.size() ; i+=2) {
                float x = tabletDrawing.get(i);
                float y = tabletDrawing.get(i+1);
                if(x < 0.f || y < 0.f || px < 0.f || py < 0.f) {
                    px = x;
                    py = y;
                    continue;
                }
                line(px, py, x, y);
                px = x;
                py = y;
            }
            // if(!mousePressed) {
            //     line(px, py, fx, fy);
            // }
        }


        pmousePressed = mousePressed;
    }
}

public void drawGondola() {
    stroke(gondolaColor);
    strokeWeight(2);
    line(scaleX(0), scaleY(0), scaleX(currentX), scaleY(currentY));
    line(scaleX(machineWidth), scaleY(0), scaleX(currentX), scaleY(currentY));
    fill(textColor);
    stroke(gridColor);
    if (motorsOn)
        fill(motorOnColor);
    else
        fill(motorOffColor);
    ellipse(scaleX(0), scaleY(0), 20, 20);
    ellipse(scaleX(machineWidth), scaleY(0), 20, 20);
}

public void drawPage() {
    stroke(gridColor);
    strokeWeight(2);
    fill(machineColor);
    rect(scaleX(0), scaleY(0), machineWidth * zoomScale, machineHeight * zoomScale);

}

public void drawPaper() {
    fill(pageColor);
    stroke(gridColor);
    strokeWeight(0.4f);
    float pWidth = paperWidth * 25.4f;
    float pHeight = paperHeight * 25.4f;
    //       rect(scaleX(homeX - pHeight / 2), scaleY(homeY), pHeight * zoomScale, pWidth * zoomScale);
    rect(scaleX(homeX - pWidth / 2), scaleY(homeY), pWidth * zoomScale, pHeight * zoomScale);
    //   noFill();
    //   rect(scaleX(homeX - pWidth / 2), scaleY(homeY), pWidth * zoomScale, pHeight * zoomScale);
    //   rect(scaleX(homeX - pHeight / 2), scaleY(homeY), pHeight * zoomScale, pWidth * zoomScale);


}

public void drawImageFrame() {
    noFill();
    stroke(cropColor);
    strokeWeight(2);
    line(cropLeft, cropTop, cropRight, cropTop);
    line(cropRight, cropTop, cropRight, cropBottom);
    line(cropRight, cropBottom, cropLeft, cropBottom);
    line(cropLeft, cropBottom, cropLeft, cropTop);
    rect(cropLeft, cropTop + (cropBottom - cropTop) / 2 - 5, 10, 10);
    rect(cropLeft + (cropRight - cropLeft) / 2 - 5, cropTop, 10, 10);
    rect(cropRight - 10, cropTop + (cropBottom - cropTop) / 2 - 5, 10, 10);
    rect(cropLeft + (cropRight - cropLeft) / 2 - 5, cropBottom - 10, 10, 10);
}

public void drawSelector() {

    if (tabletMode) {
        return;
    }

    if (overCropLeft(startX, startY)) {
        fill(cropColor);
        stroke(cropColor);
        rect(cropLeft, cropTop + (cropBottom - cropTop) / 2 - 5, 10, 10);
        cropLeft = mouseX;
        if (cropLeft < imageX)
            cropLeft = imageX;
        if (cropLeft > cropRight - 20)
            cropLeft = cropRight - 20;
    } else if (overCropRight(startX, startY)) {
        fill(cropColor);
        stroke(cropColor);
        rect(cropRight - 10, cropTop + (cropBottom - cropTop) / 2 - 5, 10, 10);

        cropRight = mouseX;
        if (cropRight < imageX + 20)
            cropRight = imageX + 20;
        if (cropRight > imageX + imageWidth)
            cropRight = imageX + imageWidth;
    } else if (overCropTop(startX, startY)) {
        fill(cropColor);
        stroke(cropColor);
        rect(cropLeft + (cropRight - cropLeft) / 2 - 5, cropTop, 10, 10);
        cropTop = mouseY;
        if (cropTop < imageY)
            cropTop = imageY;
        if (cropTop > imageY + imageHeight - 20)
            cropTop = imageY + imageHeight - 20;
    } else if (overCropBottom(startX, startY)) {
        fill(cropColor);
        stroke(cropColor);
        rect(cropLeft + (cropRight - cropLeft) / 2 - 5, cropBottom - 10, 10, 10);
        cropBottom = mouseY;
        if (cropBottom < imageY - 20)
            cropBottom = imageY - 20;
        if (cropBottom > imageY + imageHeight)
            cropBottom = imageY + imageHeight;
    }
}

public void drawOrigin() {
    noFill();
    stroke(gridColor);
    strokeWeight(0.1f);
    line(scaleX(0), scaleY(homeY), scaleX(machineWidth), scaleY(homeY));
    line(scaleX(homeX), scaleY(0), scaleX(homeX), scaleY(machineHeight));
}

public void drawTicks() {
    stroke(gridColor);
    strokeWeight(0.1f);
    for (int x = 0; x < machineWidth; x += 10) {
        line(scaleX(x), scaleY(homeY - 5), scaleX(x), scaleY(homeY + 5));
    }
    for (int y = 0; y < machineHeight; y += 10) {

        line(scaleX(homeX - 5), scaleY(y), scaleX(homeX + 5), scaleY(y));
    }
}

void setPlotFromJSON(JSONObject object) {

    float pWidth = paperWidth * 25.4f;
    float pHeight = paperHeight * 25.4f;

    JSONObject bounds = object.getJSONObject("bounds");
    float oX = homeX - pWidth / 2;                       // machineWidth/2;
    float oY = -offY-homeY;
    // float oY = paperHeight * 25.4 / 2.0;  // machineHeight/2;
    float bx = bounds.getFloat("x");
    float by = bounds.getFloat("y");
    float bw = bounds.getFloat("width");
    float bh = bounds.getFloat("height");
    JSONArray paths = object.getJSONArray("paths");


    float scale = 1.0; // object.getFloat("scale")/100;

    if(paths.size() > 0) {

        RShape shape = new RShape();
        for (int i = 0; i < paths.size(); i++) {
            JSONArray points = paths.getJSONArray(i);
            RPath path = null;
            for (int j = 0; j < points.size(); j++) {
                JSONObject point = points.getJSONObject(j);
                float x = point.getFloat("x");
                float y = point.getFloat("y");
                println("x: " + x + ", y: " + y);
                RPoint p = new RPoint(oX + ((x - bx) / bw) * pWidth / scaleX, oY + ((y - by) / bh) * pHeight / scaleY);
                if (j == 0) {
                    path = new RPath(p);
                } else {
                    path.addLineTo(p);
                }
            }
            shape.addPath(path);

            RPath paperBounds = new RPath(new RPoint(oX, oY));
            paperBounds.addLineTo(new RPoint(oX+pWidth / scaleX, oY+0.0));
            paperBounds.addLineTo(new RPoint(oX+pWidth / scaleX, oY+pHeight / scaleY));
            paperBounds.addLineTo(new RPoint(oX+0.0, oY+pHeight / scaleY));
            paperBounds.addLineTo(new RPoint(oX+0.0, oY+0.0));
            shape.addPath(paperBounds);
        }

        currentPlot.clear(); // or reset();  resets and calls plotDone() which reset the plot button :-)

        currentPlot = new SvgPlot();
        ((SvgPlot)currentPlot).optimize(shape);
        ((SvgPlot)currentPlot).sh = shape;
        currentPlot.loaded = true;
        currentPlot.showControls(); // not necessary but fancy
    }
}

void setPenPosition(JSONObject object) {
    
    if (currentPlot.isPlotting()) {
        currentPlot.clear(); // or reset();  resets and calls plotDone() which reset the plot button :-)
    }

    String direction = object.getString("direction");
    if (direction.equals("up")) {
        com.sendPenUp();
    } else if (direction.equals("down")) {
        com.sendPenDown();
    }

}

void goToMoveTo(JSONObject object) {

    if (currentPlot.isPlotting()) {
        currentPlot.clear(); // or reset();  resets and calls plotDone() which reset the plot button :-)
    }
    String type = object.getString("type");
    JSONObject point = object.getJSONObject("point");
    println("point: "+point);

    float x = point.getFloat("x");
    float y = point.getFloat("y");
    println("x: "+x);
    println("y: "+y);
    
    JSONObject bounds = object.getJSONObject("bounds");
    println("bounds: "+bounds);

    float oX = 0.0;                       // machineWidth/2;
    float oY = paperHeight * 25.4 / 2.0;  // machineHeight/2;
    float bx = bounds.getFloat("x");
    println("bx: "+bx);
    float by = bounds.getFloat("y");
    println("by: "+by);
    float bw = bounds.getFloat("width");
    println("bw: "+bw);
    float bh = bounds.getFloat("height");
    println("bh: "+bh);

    JSONObject scale = object.getJSONObject("scale");
    float scaleX = scale.getFloat("x");
    float scaleY = scale.getFloat("y");

    println("scale: " + scaleX + ", " + scaleY);

    JSONObject offset = object.getJSONObject("offset");
    float offsetX = offset.getFloat("x");
    float offsetY = offset.getFloat("y");
    
    println("offset: " + offsetX + ", " + offsetY);

    float pWidth = paperWidth * 25.4f;
    float pHeight = paperHeight * 25.4f;

    float machineX = homeX - pWidth / 2; // scaleX(0);
    float machineY = homeY;// scaleY(0);

    // float tx = ( ( pWidth - 2 * tabletMarginX ) * ( mouseX - tabletX ) / tabletWidth ) + machineX + tabletMarginX;
    // float ty = ( ( pHeight - 2 * tabletMarginY ) * ( mouseY - tabletY ) / tabletHeight ) + machineY + tabletMarginY;

    // RPoint p = new RPoint(oX + (x - bx - bw / 2) * scale, oY + (y - by - bh / 2) * scale);
    RPoint p = new RPoint( (((x - bx + offsetX) / bw) * scaleX) * pWidth + machineX, (((y - by + offsetY) / bh)  * scaleY)  * pHeight + machineY);

    float px = p.x;
    float py = p.y;

    gpsCoordsFileWriter.println(x + ", " + y + " - " + px + ", " + py);
    gpsCoordsFileWriter.flush();
    // println("p: ");

    // float px = p.x + machineWidth / 2 + offX;
    // println("px: "+px);
    // float py = p.y + homeY + offY;
    // println("py: "+py);
    
    try {
        if (type.equals("moveTo")) {
            println("send move: ");
            com.sendMoveG0(px, py);
        } else if (type.equals("goTo")) {
            println("send goto: ");
            com.sendMoveG1(px, py);
        }
    } catch( Exception e ){
        println("error: " + e);
    }
    
    println("currentX: "+currentX);
    currentX = px;
    currentY = py;
}

void webSocketServerEvent(String msg) {
    JSONObject object = parseJSONObject(msg);
    String type = object.getString("type");
    println("type: "+type);

    if (type.equals("setPlot")) {
        setPlotFromJSON(object);
    } else if (type.equals("setNextDrawing")) {
        
        // drawingRequestSent = false;
        isDrawing = true;
        setPlotFromJSON(object);

    } else if (type.equals("pen")) {
        setPenPosition(object);
    } else if (type.equals("goTo") || type.equals("moveTo")) {
        goToMoveTo(object);
    }
}

void orthoToPolar(float x, float y, RPoint lr) {
  float x2 = x * x;
  float y2 = y * y;
  float WmX = machineWidth - x;
  float WmX2 = WmX * WmX;
  lr.x = sqrt(x2 + y2);
  lr.y = sqrt(WmX2 + y2);
}

void polarToOrtho(float l, float r, RPoint xy) {
  float l2 = l * l;
  float r2 = r * r;
  float w2 = machineWidth * machineWidth;
  xy.x = (l2 - r2 + w2) / ( 2.0 * machineWidth );
  float x2 = xy.x * xy.x;
  xy.y = sqrt(l2 - x2);
}