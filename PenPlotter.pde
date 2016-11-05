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

// import codeanticode.tablet.*;
// Tablet tablet;

boolean tabletMode = false;
boolean pmousePressed = false;

// import spacebrew.*;


String server="localhost";
String name="Tipibot";
String description ="Tipibot commands.";


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
    int homeX = machineWidth/2; //X Home position
    int machineHeight = 800;    //machine Height only used to draw page height
    int homeY = 250;          // location of homeY good location is where gondola hangs with motor power off
    int homeOffsetY = 2250;
    
    float currentX = homeX;   // X location of gondola
    float currentY = homeY;   // X location of gondola

    int tabletX = 0;
    int tabletY = 0;
    int tabletWidth = width;
    int tabletHeight = height;
    int tabletMarginX = 0;
    int tabletMarginY = 0;
    
    int speedValue = 20000;     // speed of motors controlled with speed slider


    float stepsPerRev = 6400; // number of steps per rev includes microsteps
    float mmPerRev = 80;      // mm per rev

    float zoomScale = 0.75f;   // screen scale controlle with mouse wheel
    float shortestSegment = 0;    // cull out svg segments shorter that is.


    int menuWidth = 140;
    int originX = (machineWidth+menuWidth)/2; // screen X offset of page will change if page dragged
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
    int cropRight = imageX+imageWidth;
    int cropBottom = imageY+imageHeight;

    String currentFileName = "";

    boolean overLeft = false;
    boolean overRight = false;
    boolean overTop = false;
    boolean overBottom = false;
    boolean motorsOn = false;


    int pageColor = color(255, 255, 255);
    int machineColor = color(250,250,250);
    int backgroundColor = color(192, 192, 192);
    int gridColor = color(128, 128, 128);
    int cropColor = color(0, 255, 0);
    int textColor = color(113, 113, 113);
    int gondolaColor = color(0, 0, 0,128);
    int statusColor = color(0, 0, 0);
    int motorOnColor = color(239, 136, 93);
    int motorOffColor = color(44, 175, 161);
    
    int penColor = color(0, 0, 0,255);    
    int previewColor = color(0,0,0,255);
    int whilePlottingColor = color(0,0,0,64);
    int rapidColor = color(0,255,0,64);
    
    int buttonPressColor = color(195, 241, 236);
    int buttonHoverColor = color(239, 136, 93);
    int buttonUpColor = color(44, 175, 161);
    int buttonTextColor = color(0,0,0);
    int buttonBorderColor = color(0,0,0);

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
    
    float paperWidth = 8.5;
    float paperHeight = 11;
    public static Console console;
    Com com = new Com();
    boolean settingPenPosition = false;
    boolean setPenPositionButtonJustPressed = false;

    private void prepareExitHandler () {

        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {

            public void run() {
                println("SHUTDOWN HOOK");
            }
        }
        ));
    }

    public void exit()
    {
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
        
                   
        // tablet = new Tablet(this);
        
        // Spacebrew communication:
        
        // instantiate the spacebrewConnection variable
        // sb = new Spacebrew( this );
      
        // declare your publishers
        // sb.addPublish( "local_slider", "range", local_slider_val ); 
        // sb.addPublish( "button_pressed", "boolean", true);
        
        // declare your subscribers
        // sb.addSubscribe( "commands", "string" );
        // sb.addSubscribe( "command", "string" );
      
        // connect!
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
        tabletX = tabletY < 0 ? 0 : tabletY;
        tabletWidth = Integer.parseInt(props.getProperty("tablet.width"));
        tabletWidth = tabletWidth < 0 ? 0 : width;
        tabletHeight = Integer.parseInt(props.getProperty("tablet.height"));
        tabletWidth = tabletHeight < 0 ? 0 : height;
        
        tabletMarginX = Integer.parseInt(props.getProperty("tablet.margin.x"));
        tabletMarginY = Integer.parseInt(props.getProperty("tablet.margin.y"));
          
        machineWidth = Integer.parseInt(props.getProperty("machine.width"));
        machineHeight = Integer.parseInt(props.getProperty("machine.height"));
        homeX = machineWidth/2;

        homeY = Integer.parseInt(props.getProperty("machine.homepoint.y"));
        homeOffsetY = Integer.parseInt(props.getProperty("machine.homepoint.offsety"));
        mmPerRev = Float.parseFloat(props.getProperty("machine.motors.mmPerRev"));
        stepsPerRev = Float.parseFloat(props.getProperty("machine.motors.stepsPerRev"));

        currentX = homeX;
        currentY = homeY+homeOffsetY;

        penWidth = Float.parseFloat(props.getProperty("machine.penSize"));

        svgDpi = Float.parseFloat(props.getProperty("svg.pixelsPerInch"));
        svgScale = 25.4f/svgDpi;

        currentFileName = props.getProperty("svg.name");

        cncSafeHeight = Float.parseFloat(props.getProperty("cnc.safeHeight"));


        com.baudRate = Long.parseLong(props.getProperty("com.baudrate"));
        //todo lastPort not used

        com.lastPort = Integer.parseInt(props.getProperty("com.serialPort"));
        
        zoomScale = Float.parseFloat(props.getProperty("machine.zoomScale"));

        cropLeft = Integer.parseInt(props.getProperty("image.cropLeft"));
        if(cropLeft < imageX) cropLeft = imageX;
        cropRight = Integer.parseInt(props.getProperty("image.cropRight"));
        if(cropRight > imageX+imageWidth) cropRight = imageX+imageWidth;
        cropTop = Integer.parseInt(props.getProperty("image.cropTop"));
        if(cropTop < imageY) cropTop = imageY;
        cropBottom = Integer.parseInt(props.getProperty("image.cropBottom"));
        if(cropBottom > imageY+imageHeight) cropBottom = imageY+imageHeight;

        paperWidth = Float.parseFloat(props.getProperty("paper.width"))/25.4;
        paperHeight = Float.parseFloat(props.getProperty("paper.height"))/25.4;
        
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

        pixelSize = Integer.parseInt(props.getProperty("image.pixelSize"));
        pixelSizeSlider.setValue(pixelSize);

        userScale = Float.parseFloat(props.getProperty("svg.UserScale"));
        scaleSlider.setValue(userScale);
        
        
        
        updateScale();

        handles = new Handle[6];
        handles[0] = new Handle("homeY", 0, homeY, 0, 10, handles, false, true, 128);
        handles[1] = new Handle("mWidth", machineWidth, machineHeight/2, 0, 10, handles, true, false, 64);
        handles[2] = new Handle("mHeight", homeX, machineHeight, 0, 10, handles, false, true, 64);
        handles[3] = new Handle("gondola", (int)currentX, (int)currentY, 0, 10, handles, true, true, 2);
        handles[4] = new Handle("pWidth", Math.round(homeX+(paperWidth/2)*25.4), Math.round(homeY+(paperHeight/2)*25.4f), 0, 10, handles, true, false, 64);
        handles[5] = new Handle("pHeight", homeX, Math.round(homeY+(paperHeight)*25.4), 0, 10, handles, false, true, 64);
    }

    public void mousePressed()
    {
        if(tabletMode)
        {
            return;
        }
        startX = mouseX;
        startY = mouseY;
        oldOriginX = originX;
        oldOriginY = originY;
        oldOffX = offXTopLeft;
        oldOffY = offY;
    }

    public void mouseDragged()
    {
        if(tabletMode)
        {
            return;
        }
        if (mouseButton == CENTER) {
            originX = oldOriginX + mouseX -startX;
            originY = oldOriginY + mouseY -startY;
        } else if (mouseButton == RIGHT)
        {
            offXTopLeft = oldOffX + (int)((mouseX - startX)/zoomScale);
            offY = oldOffY + (int)((mouseY - startY)/zoomScale);
            offsetXSlider.setValue(offXTopLeft);
            offsetYSlider.setValue(offY);
            
            offX = - int(paperWidth * 25.4f / 2.f) + offXTopLeft;
        }
    }

    public void mouseReleased() {
 
        if(tabletMode)
        {
            return;
        }
        
        if (overLeft || overRight || overTop || overBottom)
        {
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

                    com.sendMoveG0(currentX, currentY);
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
        
        if(settingPenPosition && !setPenPositionButtonJustPressed)
        {
            setPenPositionButton.setCaptionLabel("Set pen position");
            settingPenPosition = false;
            com.sendSetPositionG92((mouseX-scaleX(0))/zoomScale, (mouseY-scaleY(0))/zoomScale);
        }
        if(setPenPositionButtonJustPressed)
        {
          setPenPositionButtonJustPressed = false;
        }
    }

    public void mouseWheel(MouseEvent event) {

        float e = event.getCount();

        if (e > 0)
            setZoom(zoomScale+=0.1f);
        else if(zoomScale > 0.1f)
            setZoom(zoomScale-=0.1f);
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
        
        if (key == 'c')
         {
           println("control");
           initLogging();
         }
    }
void initLogging()
{
  try
  {
      console = new Console();
  }
  catch(Exception e)
  {
    println("Exception setting up logger: " + e.getMessage());
  }
}
    public void handleMoved(String id, int x, int y)
    {
        if(tabletMode)
        {
            return;
        }
        if (id.equals("homeY"))
            homeY = y;
        else if(id.equals("gondola")) {

            currentX = x;
            currentY = y;
        }
        else if(id.equals("mWidth")) {
            machineWidth = x;
            homeX = machineWidth / 2;
            handles[2].x = homeX;
            //makeHatchImage();

        }
        else if(id.equals("mHeight")) {
            machineHeight = y;
            handles[1].y = y / 2;
           // makeHatchImage();
        }
        else if(id.equals("pWidth"))
        {
          paperWidth = (x-homeX)*2/25.4;
        }
        else if(id.equals("pHeight"))
        {
          paperHeight = (y-homeY)/25.4;
        }
    }

    public boolean overCropLeft(int x, int y)
    {
        if (overLeft) return true;

        int x1 = cropLeft;
        int x2 = x1+10;
        int y1 = cropTop+(cropBottom-cropTop)/2-5;
        int y2 = y1+10;

        if (x < x1) return false;
        if (x > x2) return false;
        if (y < y1) return false;
        if (y > y2) return false;

        overLeft = true;
        return true;
    }

    public boolean overCropRight(int x, int y)
    {
        if (overRight) return true;

        int x1 = cropRight-10;
        int x2 = x1+10;
        int y1 = cropTop+(cropBottom-cropTop)/2-5;
        int y2 = y1+10;

        if (x < x1) return false;
        if (x > x2) return false;
        if (y < y1) return false;
        if (y > y2) return false;

        overRight = true;
        return true;
    }

    public boolean overCropTop(int x, int y)
    {
        if (overTop) return true;

        int x1 = cropLeft+(cropRight-cropLeft)/2-5;
        int x2 = x1+10;
        int y1 = cropTop;
        int y2 = y1+10;

        if (x < x1) return false;
        if (x > x2) return false;
        if (y < y1) return false;
        if (y > y2) return false;

        overTop = true;
        return true;
    }

    public boolean overCropBottom(int x, int y)
    {
        if (overBottom) return true;

        int x1 = cropLeft+(cropRight-cropLeft)/2-5;
        int x2 = x1+10;
        int y1 = cropBottom-10;
        int y2 = y1+10;

        if (x < x1) return false;
        if (x > x2) return false;
        if (y < y1) return false;
        if (y > y2) return false;

        overBottom = true;
        return true;
    }

    public void setSpeed(int value)
    {
        speedValue = value;
        com.sendSpeed(speedValue);
    }

    public void setuserScale(float value) {
        userScale = value;
        updateScale();
        setImageScale();
    }

    public void updateScale()
    {
        scaleX = svgScale*userScale*flipX;
        scaleY = svgScale*userScale*flipY;
    }

    public void setImageScale() {
        currentPlot.crop(cropLeft, cropTop, cropRight, cropBottom);
    }

    public void setZoom(float value)
    {
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

    public float unScaleX(float x)
    {
        return (x-originX)/zoomScale+homeX;
    }

    public float unScaleY(float y)
    {
        return (y-originY)/zoomScale+homeY;
    }

    public float scaleX(float x)
    {
        return (x-homeX)*zoomScale + originX;
    }

    public float scaleY(float y)
    {
        return (y-homeY)*zoomScale + originY;
    }

    public void updatePos(float x, float y)
    {
        currentX = x;
        currentY = y;
        handles[3].x = x;
        handles[3].y = y;
        motorsOn = true;
    }

    public void sline(float x1, float y1, float x2, float y2)
    {
        strokeWeight(0.5f);
        line(scaleX(x1), scaleY(y1), scaleX(x2), scaleY(y2));
    }

    public void draw()
    {
        
        background(backgroundColor);

        drawPage();
        drawOrigin();
        drawTicks(); 
        drawPaper();

        if(!tabletMode)
        {
          for (Handle handle : handles) {
              handle.update();
              handle.display();
          }
        }
        
        if (currentPlot.isLoaded())
        {
            currentPlot.draw();
        }
      
        drawGondola();

        if (oimg != null)
        {
            image(oimg, imageX, imageY, imageWidth, imageHeight);
            drawImageFrame();
            drawSelector();
        }
        
        if (jogX != 0)
        {
            com.moveDeltaX(jogX);
        }
        if (jogY != 0)
        {
            com.moveDeltaY(jogY);
        }
        com.serialEvent();
        tick++;
        if(millis() > lastTime+1000)
        {
          rate = tick;
          tick = 0;
          freeMemory = Runtime.getRuntime().freeMemory()/1000000;
          totalMemory = Runtime.getRuntime().totalMemory()/1000000;
          lastTime = millis();
        }
        stroke(statusColor);
        fill(statusColor);
        text("FPS: "+nf(rate,2,0) +"  Mem: "+freeMemory+"/"+totalMemory+"M",10,height-4);
        String status = " Size: "+machineWidth+"x"+machineHeight +" Zoom: "+nf(zoomScale, 0, 2);
        status += " X: "+nf(currentX, 0, 2)+" Y: "+nf(currentY, 0, 2);
        status += " A: "+nf(getMachineA(currentX, currentY), 0, 2);
        status += " B: "+nf(getMachineB(currentX, currentY), 0, 2);
        if(currentPlot.isLoaded())
          status += " Plot: "+currentPlot.progress();
        text(status, 150, height-4);
        
        
        if (tabletMode) {
          println("mp: " + mouseX + ", " + mouseY);
          
          
          
          float pWidth = paperWidth*25.4f;
          float pHeight = paperHeight*25.4f;
          
          // rect(scaleX(homeX - pWidth / 2), scaleY(homeY), pWidth * zoomScale, pHeight * zoomScale);
        
          float machineX = homeX - pWidth/2;// scaleX(0);
          float machineY = homeY;// scaleY(0);
          
          float tx = ( ( pWidth - 2 * tabletMarginX ) * ( mouseX - tabletX ) / tabletWidth ) + machineX + tabletMarginX;
          float ty = ( ( pHeight - 2 * tabletMarginY ) * ( mouseY - tabletY ) / tabletHeight ) + machineY + tabletMarginY;
          
          
          if(mousePressed && !pmousePressed)
          {
              com.sendMoveG0(tx, ty);
              com.sendPenDown();
          }
          else if(mousePressed && pmousePressed)
          {
              com.sendMoveG1(tx, ty);
          }
          else if(!mousePressed && pmousePressed)
          {
              com.sendPenUp();
          }
          pmousePressed = mousePressed;
        }
    }

    public void drawGondola()
    {
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

    public void drawPage()
    {
        stroke(gridColor);
        strokeWeight(2);
        fill(machineColor);
        rect(scaleX(0), scaleY(0), machineWidth*zoomScale, machineHeight*zoomScale);

    }

    public void drawPaper()
    {
        fill(pageColor);
        stroke(gridColor);
        strokeWeight(0.4f);
        float pWidth = paperWidth*25.4f;
        float pHeight = paperHeight*25.4f;
 //       rect(scaleX(homeX - pHeight / 2), scaleY(homeY), pHeight * zoomScale, pWidth * zoomScale);
        rect(scaleX(homeX - pWidth / 2), scaleY(homeY), pWidth * zoomScale, pHeight * zoomScale);
     //   noFill();
     //   rect(scaleX(homeX - pWidth / 2), scaleY(homeY), pWidth * zoomScale, pHeight * zoomScale);
     //   rect(scaleX(homeX - pHeight / 2), scaleY(homeY), pHeight * zoomScale, pWidth * zoomScale);
        

    }

    public void drawImageFrame()
    {
        noFill();
        stroke(cropColor);
        strokeWeight(2);
        line(cropLeft, cropTop, cropRight, cropTop);
        line(cropRight, cropTop, cropRight, cropBottom);
        line(cropRight, cropBottom, cropLeft, cropBottom);
        line(cropLeft, cropBottom, cropLeft, cropTop);
        rect(cropLeft, cropTop+(cropBottom-cropTop)/2-5, 10, 10);
        rect(cropLeft+(cropRight-cropLeft)/2-5, cropTop, 10, 10);
        rect(cropRight-10, cropTop+(cropBottom-cropTop)/2-5, 10, 10);
        rect(cropLeft+(cropRight-cropLeft)/2-5, cropBottom-10, 10, 10);
    }

    public void drawSelector()
    {
      
        if(tabletMode)
        {
            return;
        }
        
        if (overCropLeft(startX, startY))
        {
          fill(cropColor);
          stroke(cropColor);
          rect(cropLeft, cropTop+(cropBottom-cropTop)/2-5, 10, 10);
            cropLeft = mouseX;
            if (cropLeft < imageX)
                cropLeft = imageX;
            if (cropLeft > cropRight-20)
                cropLeft = cropRight-20;
        } else if (overCropRight(startX, startY))
        {
          fill(cropColor);
          stroke(cropColor);
          rect(cropRight-10, cropTop+(cropBottom-cropTop)/2-5, 10, 10);
          
            cropRight = mouseX;
            if (cropRight < imageX+20)
                cropRight = imageX+20;
            if (cropRight > imageX+imageWidth)
                cropRight = imageX+imageWidth;
        } else if (overCropTop(startX, startY))
        {
          fill(cropColor);
          stroke(cropColor);
          rect(cropLeft+(cropRight-cropLeft)/2-5, cropTop, 10, 10);
            cropTop = mouseY;
            if (cropTop < imageY)
                cropTop = imageY;
            if (cropTop > imageY+imageHeight-20)
                cropTop = imageY+imageHeight-20;
        } else if (overCropBottom(startX, startY))
        {
          fill(cropColor);
          stroke(cropColor);
          rect(cropLeft+(cropRight-cropLeft)/2-5, cropBottom-10, 10, 10);
            cropBottom = mouseY;
            if (cropBottom < imageY-20)
                cropBottom = imageY-20;
            if (cropBottom > imageY+imageHeight)
                cropBottom = imageY+imageHeight;
        }
    }

    public void drawOrigin()
    {
        noFill();
        stroke(gridColor);
        strokeWeight(0.1f);
        line(scaleX(0), scaleY(homeY), scaleX(machineWidth), scaleY(homeY));
        line(scaleX(homeX), scaleY(0), scaleX(homeX), scaleY(machineHeight));
    }

    public void drawTicks()
    {
        stroke(gridColor);
        strokeWeight(0.1f);
        for (int x = 0; x<machineWidth; x+=10)
        {
            line(scaleX(x), scaleY(homeY-5), scaleX(x), scaleY(homeY+5));
        }
        for (int y = 0; y<machineHeight; y+=10)
        {

            line(scaleX(homeX - 5), scaleY(y), scaleX(homeX + 5), scaleY(y));
        }
    }
    
    
void onCustomMessage( String name, String type, String value )
{
  println("got range message " + name + " : " + value + ", type: " + type);
}

void onStringMessage( String name, String value ){
  println("got string message " + name + " : " + value);
  if(name.equals("commands"))
  {
    JSONObject object = parseJSONObject(value);
    JSONObject bounds = object.getJSONObject("bounds");
    float oX = 0.0;                       // machineWidth/2;
    float oY = paperHeight * 25.4 / 2.0;  // machineHeight/2;
    float bx = bounds.getFloat("x");
    float by = bounds.getFloat("y");
    float bw = bounds.getFloat("width");
    float bh = bounds.getFloat("height");
    JSONArray paths = object.getJSONArray("paths");
    
    float scale = 1.0; // object.getFloat("scale")/100; 
  
    RShape shape = new RShape();
    for (int i = 0; i < paths.size(); i++)
    {
      JSONArray points = paths.getJSONArray(i);
      RPath path = null;
      for (int j = 0; j < points.size(); j++)
      {
        JSONObject point = points.getJSONObject(j);
        float x = point.getFloat("x");
        float y = point.getFloat("y");
        println("x: " + x + ", y: " + y);
        RPoint p = new RPoint(oX + (x - bx - bw/2)*scale, oY + (y - by - bh/2)*scale);
        if(j==0)
        {
          path = new RPath(p);
        }
        else
        {
          path.addLineTo(p);
        }
      }
      shape.addPath(path);
    }
    
    currentPlot.clear(); // or reset();  resets and calls plotDone() which reset the plot button :-)
    
    currentPlot = new SvgPlot();
    ((SvgPlot)currentPlot).optimize(shape);
    ((SvgPlot)currentPlot).sh = shape;
    currentPlot.loaded = true;
    currentPlot.showControls(); // not necessary but fancy
  }
  else if(name.equals("command"))
  {
    if(currentPlot.isPlotting())
    {
      currentPlot.clear(); // or reset();  resets and calls plotDone() which reset the plot button :-)
    }
    
    JSONObject object = parseJSONObject(value);
    String type = object.getString("type");
    if(type.equals("pen"))
    {
      String direction = object.getString("direction");
      if(direction.equals("up"))
      {
        com.sendPenUp();
      }
      else if(direction.equals("down"))
      {
        com.sendPenDown();
      }
    }
    else if(type.equals("goTo") || type.equals("moveTo"))
    {
      JSONObject point = object.getJSONObject("point");
      float x = point.getFloat("x");
      float y = point.getFloat("y");
      
      JSONObject bounds = object.getJSONObject("bounds");
      float oX = 0.0;                       // machineWidth/2;
      float oY = paperHeight * 25.4 / 2.0;  // machineHeight/2;
      float bx = bounds.getFloat("x");
      float by = bounds.getFloat("y");
      float bw = bounds.getFloat("width");
      float bh = bounds.getFloat("height");
      float scale = object.getFloat("scale")/100;
      RPoint p = new RPoint(oX + (x - bx - bw/2)*scale, oY + (y - by - bh/2)*scale);
      if(type.equals("moveTo"))
      {
        com.sendMoveG0(p.x + machineWidth / 2 + offX, p.y+ homeY + offY);
      }
      else if(type.equals("goTo"))
      {
        com.sendMoveG1(p.x + machineWidth / 2 + offX, p.y+ homeY + offY);
      }
    }
  }
}

void onBooleanMessage( String name, boolean value )
{
  println("got bool message " + name + " : " + value);
}