class Message {
    String command;
    byte[] bytes;
    Message() {
        command = null;
        bytes = null;
    }
}

 class Com {
    Serial myPort;  //the Serial port object
    String val;
    String lastCmd;
    byte[] lastBytes;
    ArrayList<Message> buf = new ArrayList<Message>();

    ArrayList<RPoint> fastModeCommands = new ArrayList<RPoint>();

    ArrayList<String> comPorts = new ArrayList<String>();
    long baudRate = 9600;
    int lastPort;
    int okCount = 0;
    boolean initSent;
    boolean fastModeActivated = false;

    public void listPorts() {
        //  initialize your serial port and set the baud rate to 9600

        comPorts.add("Disconnected");

        for (int i = 0; i < Serial.list().length; i++) {
            String name = Serial.list()[i];
            int dot = name.indexOf('.');
            if (dot >= 0)
                name = name.substring(dot + 1);
            if (!name.contains("luetooth")) {
                comPorts.add(name);
                println(name);
            }
        }
    }

    public void disconnect() {
        clearQueue();
        if (myPort != null)
            myPort.stop();
        myPort = null;


        //  myTextarea.setVisible(false);
    }

    public void connect(int port) {
        clearQueue();
        try {
            myPort = new Serial(applet, Serial.list()[port], (int) baudRate);
            lastPort = port;
            println("connected");
            myPort.write("\n");
        } catch (Exception exp) {
            exp.printStackTrace();
            println(exp);
        }
    }

    public void connect(String name) {
        for (int i = 0; i < Serial.list().length; i++) {
            if (Serial.list()[i].contains(name)) {
                connect(i);
                return;
            }
        }
        disconnect();
    }

    public void sendMotorOff() {
        motorsOn = false;
        send("M84\n");
    }

    public void moveDeltaX(float x) {
        send("G0 X" + x + "\n");
        updatePos(currentX + x, currentY);
    }

    public void moveDeltaY(float y) {
        send("G0 Y" + y + "\n");
        updatePos(currentX, currentY + y);
    }

    public void sendMoveG0(float x, float y) {
        if(fastMode) {
            sendFastMove(new RPoint(x, y), true, true);
        } else {
            send("G0 X" + x + " Y" + y + "\n");
        }
        updatePos(x, y);
    }
    
    public void sendSetPositionG92(float x, float y) {
        send("G92 X" + x + " Y" + y + "\n");
        updatePos(x, y);
    }

    public void sendMoveG1(float x, float y) {
        if(fastMode) {
            sendFastMove(new RPoint(x, y), true, true);
            // fastModeCommands.add(new RPoint(x, y));
        } else {
            send("G1 X" + x + " Y" + y + "\n");
        }
        updatePos(x, y);
    }

    public void sendG2(float x, float y, float i, float j) {
        send("G2 X" + x + " Y" + y + " I" + i + " J" + j + "\n");
        updatePos(x, y);
    }
    
    public void sendG2(float x, float y, float r) {
        send("G2 X" + x + " Y" + y + " R" + r+"\n");
        updatePos(x, y);
    }

    public void sendG3(float x, float y, float i, float j) {
        send("G3 X" + x + " Y" + y + " I" + i + " J" + j + "\n");
        updatePos(x, y);
    }
    
    public void sendG3(float x, float y, float r) {
        send("G3 X" + x + " Y" + y + " R" + r+"\n");
        updatePos(x, y);
    }
    
    public void sendPause(int delay) {
        send("G4 P" + delay +"\n");
    }

    public void sendSpeed(int speed) {
        send("G0 F" + speed + "\n");
    }

    public void sendHome() {
        send("M1 Y" + (homeY + homeOffsetY) + "\n");
        updatePos(homeX, homeY + homeOffsetY);
    }

    public void sendSpeed() {
        send("G0 F" + speedValue + "\n");
    }

    public void sendPenWidth() {
        send("M4 E" + penWidth + "\n");
    }

    public void sendSpecs() {
        send("M4 X" + machineWidth + " E" + penWidth + " S" + stepsPerRev + " P" + mmPerRev + "\n");
    }

    public void sendOpenFile() {
        send("M28\n");
    }

    public void sendCloseFile() {
        send("M29\n");
    }

    public void sendPrintFile() {
        send("M24\n");
    }

    float polarStepDistance = 5.0;
    float millimetersPerRevolution = 96;
    float stepsPerRevolution = 200;
    float millimetersPerStep = millimetersPerRevolution/stepsPerRevolution;

    byte[] createFastMoveBytes(int nSteps) {
        int nBytes = abs(nSteps) / 127;
        int remaining = abs(nSteps) - nBytes * 127;
        int sign = nSteps < 0 ? -1 : 1;

        byte[] bytes = new byte[nBytes+1];
        for (int j = 0; j < nBytes + 1 ; ++j) {
            bytes[j] = j < nBytes ? byte(sign * 127+128) : byte(sign * remaining+128);
        }

        return bytes;
    }

    void sendFastMove(RPoint p, boolean bFirstChar, boolean bEndCommand) {

        float positionX = currentX;
        float positionY = currentY;
        RPoint positionLR = new RPoint(0, 0);
        orthoToPolar(positionX, positionY, positionLR);
        float positionL = positionLR.x;
        float positionR = positionLR.y;
        
        println("   positionX: " + positionX + ", positionY: " + positionY);
        println("Point: " + p.x + ", " + p.y);

        float deltaX = p.x - positionX;
        float deltaY = p.y - positionY;

        float distance = sqrt(deltaX * deltaX + deltaY * deltaY);

        int nPolarSteps = int(distance / polarStepDistance);

        float u = deltaX / distance;
        float v = deltaY / distance;

        float stepX = u * polarStepDistance;
        float stepY = v * polarStepDistance;

        println("   stepX: " + stepX + ", stepY: " + stepY);
        println("   step length: " + sqrt(stepX*stepX+stepY*stepY) + " - polarStepDistance: " + polarStepDistance);

        println(" - n polar steps: " + nPolarSteps);


        byte[] bytes = new byte[33];
        int nBytes = 0;

        for(int i=0 ; i<nPolarSteps+1 ; i++) {
            println(" - polar step: " + i);

            float destinationX = i < nPolarSteps ? positionX + (i+1) * stepX : p.x;
            float destinationY = i < nPolarSteps ? positionY + (i+1) * stepY : p.y;

            // println("   positionX: " + positionX + ", positionY: " + positionY);
            // println("   destinationX: " + destinationX + ", destinationY: " + destinationY);
            float dx = destinationX - (positionX + i * stepX);
            float dy = destinationY - (positionY + i * stepY);
            // println("   dist destination -> position: " + sqrt(dx*dx+dy*dy));

            RPoint destinationLR = new RPoint(0, 0);
            orthoToPolar(destinationX, destinationY, destinationLR);

            // println("   positionL: " + positionL + ", positionR: " + positionR);
            // println("   destinationL: " + destinationLR.x + ", destinationR: " + destinationLR.y);

            float deltaL = destinationLR.x - positionL;
            float deltaR = destinationLR.y - positionR;

            int nStepsL = round(deltaL / millimetersPerStep);
            int nStepsR = round(deltaR / millimetersPerStep);

            println("   nStepsL: " + nStepsL + ", nStepsR: " + nStepsR);

            byte[] bytesL = createFastMoveBytes(nStepsL);
            byte[] bytesR = createFastMoveBytes(nStepsR);

            int nLRBytes = max(bytesL.length, bytesR.length);
            
            for (int j = 0; j < nLRBytes ; ++j) {
                //byte[] bytes = new byte[2];
                bytes[nBytes++] = j < bytesL.length ? bytesL[j] : byte(0+128);
                bytes[nBytes++] = j < bytesR.length ? bytesR[j] : byte(0+128);
                // sendBytesPrefix(bytes, bFirstChar && !fastModeActivated);
                // fastModeActivated = bFirstChar;
                if(nBytes >= 31) {
                    bytes[32] = byte(0);
                    sendBytesPrefix(bytes, true);
                    nBytes = 0;
                }
            }

            positionL += nStepsL * millimetersPerStep;
            positionR += nStepsR * millimetersPerStep;

            updatePos(destinationX, destinationY);
        }

        if(nBytes > 0) {
            byte[] b = new byte[nBytes+1];
            for (int j = 0; j < nBytes ; ++j) {
                b[j] = bytes[j];
            }
            b[nBytes] = byte(0);
            sendBytesPrefix(b, true);
        }
        // if(bEndCommand) {
        //     send(""+char(0));
        //     fastModeActivated = false;
        // }
    }

    public void sendBytesPrefix(byte[] bytes, boolean prefix) {
        if(!prefix) {
            sendBytes(bytes);
        } else {
            byte[] b = new byte[bytes.length+1];
            b[0] = 'H';
            for(int i=0 ; i<bytes.length ; i++) {
                b[i+1] = bytes[i];
            }
            sendBytes(b);
        }
    }

    public void sendPenUp() {
        println("Pen up: ");
        // if(fastMode) {
        //     // String result = "";
        //     // for (RPoint p : fastModeCommands) {
        //     //     result += "G1 X" + p.x + " Y" + p.y + "\n";
        //     // }
        //     // println("Pen up: "+result);
        //     // send(result);

        //     for (RPoint p : fastModeCommands) {
        //         sendFastMove(p, p == fastModeCommands[0], false);
        //     }
        //     send(char(-128));
        //     fastModeCommands.clear();
        //     // send(result);
        // }
        send("G4 P" + servoUpTempo + "\n");
        send("M340 P3 S" + servoUpValue + "\n");
        send("G4 P0\n");
        showPenDown();
    }

    public void sendPenDown() {
        send("G4 P" + servoDownTempo + "\n");
        send("M340 P3 S" + servoDownValue + "\n");
        send("G4 P0\n");
        showPenUp();
    }

    public void sendAbsolute() {
        send("G90\n");
    }
    

    public void sendRelative() {
        send("G91\n");
    }
    
    public void sendMM()
    {
      send("G21\n");
    }

    public void sendPixel(float da, float db, int pixelSize, int shade, int pixelDir) {
        send("M3 X" + da + " Y" + db + " P" + pixelSize + " S" + shade + " E" + pixelDir + "\n");
    }

    public void sendData() {
        // int offset = 1;
        // for(int n=0 ; n<4 ; n++) {
        //     byte[] bytes = new byte[256/8+1];

        //     for (int i = 0; i < 256/8 ; ++i) {
        //         bytes[i] = byte(i+offset);
        //     }
        //     bytes[256/8] = byte(0);
        //     sendBytesPrefix(bytes, true);
        //     offset += 256/8;
        // }
        int nBytes = 6;
        byte[] bytes = new byte[2*nBytes+1];

        for (int i = 0; i < 2*nBytes ; ++i) {
            bytes[i] = byte(100+128);
        }
        bytes[2*nBytes] = byte(0);
        sendBytesPrefix(bytes, true);

        // send("H~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    }

    public void initArduino() {
        initSent = true;
        sendSpecs();
        sendHome();
        sendSpeed();

    }

    public void clearQueue() {
        buf.clear();
        okCount = 0;
        lastCmd = null;
        lastBytes = null;
        initSent = false;
    }

    public void queue(String msg) {
        if (myPort != null) {
            //print("Q "+msg);
            Message m = new Message();
            m.command = msg;
            buf.add(m);
        }
    }

    public void queueBytes(byte[] bytes) {
        if (myPort != null) {
            //print("Q "+bytes);
            Message m = new Message();
            m.bytes = bytes;
            buf.add(m);
        }
    }

    public void nextMsg() {
        if (buf.size() > 0) {
            Message msg = buf.get(0);
           // print("sending "+msg);
            if(msg.command != null) {
                oksend(msg.command);
            } else {
                oksendBytes(msg.bytes);
            }
            buf.remove(0);
        } else {

            if (currentPlot.isPlotting())
                currentPlot.nextPlot(true);

        }
    }

    public void send(String msg) {

        if (okCount == 0)
            oksend(msg);
        else
            queue(msg);
        
        if(fakeConnectionMode) {
            thread("nextMsg");
        }
    }

    public void sendBytes(byte[] bytes) {

        if (okCount == 0)
            oksendBytes(bytes);
        else
            queueBytes(bytes);
    }

    public void oksend(String msg) {
        print(msg);

        if (myPort != null) {
            myPort.write(msg);
            lastCmd = msg;
            lastBytes = null;
            okCount--;
            myTextarea.setText(" " + msg);
        }
    }

    public void oksendBytes(byte[] bytes) {
        print(bytes);

        if (myPort != null) {
            myPort.write(bytes);
            lastCmd = null;
            lastBytes = bytes;
            okCount--;
            myTextarea.setText(" " + bytes);
        }
    }

    public void serialEvent() {

     
        if (myPort == null || myPort.available() <= 0) return;


        val = myPort.readStringUntil('\n');
        if (val != null) {
            val = trim(val);
            if (!val.contains("wait"))
                println(val);
                
            if (val.contains("wait") || val.contains("echo"))
            {
                okCount = 0;
                if(!initSent)
                  initArduino();
                else
                  nextMsg();
            }          
            else if(val.contains("Resend") && (lastCmd != null || lastBytes != null))
            {
              okCount=0;
              if(lastCmd != null) {
                oksend(lastCmd);
              } else {
                oksendBytes(lastBytes);
              }
              
            }            
            else if (val.contains("ok")) {
                okCount=0;
                nextMsg();
            }
        }
    }
    
    public void export(File file){}

    public void stop(){
        buf.clear();
        byte[] b = new byte[1];
        b[0] = byte(0);
        sendBytes(b);
    }
}