 class SvgPlot extends Plot {
        RShape sh = null;

        int svgPathIndex = -1;        // curent path that is plotting
        int svgLineIndex = -1;        // current line within path that is plotting

        public String toString()
        {
          return "type:SVG";
        }

        public void clear() {
            sh = null;
            super.clear();
        }

        public void reset() {

            svgPathIndex = -1;
            svgLineIndex = -1;
            super.reset();
        }

        public void drawPlottedLine() {
            if (svgPathIndex < 0) {
                return;
            }
            float cx = homeX;
            float cy = homeY;

            for (int i = 0; i < penPaths.size(); i++) {
                for (int j = 0; j < penPaths.get(i).size() - 1; j++) {
                    if (i > svgPathIndex || (i == svgPathIndex && j > svgLineIndex)) return;
                    float x1 = penPaths.get(i).getPoint(j).x * scaleX + machineWidth / 2 + offX;
                    float y1 = penPaths.get(i).getPoint(j).y * scaleY + homeY + offY;
                    float x2 = penPaths.get(i).getPoint(j + 1).x * scaleX + machineWidth / 2 + offX;
                    float y2 = penPaths.get(i).getPoint(j + 1).y * scaleY + homeY + offY;


                    if (j == 0) {
                        // pen up

                        stroke(rapidColor);
                        sline(cx, cy, x1, y1);
                        cx = x1;
                        cy = y1;
                    }

                    stroke(penColor);
                    sline(cx, cy, x2, y2);
                    cx = x2;
                    cy = y2;


                    if (i == svgPathIndex && j == svgLineIndex)
                        return;
                }
            }
        }
        String progress()
        {
          if( svgPathIndex > 0)
            return svgPathIndex+"/"+penPaths.size();
          else
            return "0/"+penPaths.size();
        }

        public void sendPath() {

          float x1 = penPaths.get(svgPathIndex).getPoint(svgLineIndex).x * scaleX + machineWidth / 2 + offX;
          float y1 = penPaths.get(svgPathIndex).getPoint(svgLineIndex).y * scaleY + homeY + offY;
          float x2 = penPaths.get(svgPathIndex).getPoint(svgLineIndex + 1).x * scaleX + machineWidth / 2 + offX;
          float y2 = penPaths.get(svgPathIndex).getPoint(svgLineIndex + 1).y * scaleY + homeY + offY;


          if (svgLineIndex == 0) {
              com.sendPenUp();
              com.sendMoveG0(x1, y1);
              com.sendPenDown();
          }

          com.sendMoveG1(x2, y2);

          if(delay > 0) {
            com.sendPause(delay);
          }
          
          svgLineIndex++;
        }

        public void nextPlot(boolean preview) {
            if (svgPathIndex < 0) {
                closePlot();
                return;
            }


            if (svgPathIndex < penPaths.size()) {
              if(fastMode) {
                while(svgLineIndex < penPaths.get(svgPathIndex).size() - 1) {
                  sendPath();
                }
                svgPathIndex++;
                svgLineIndex = 0;
                nextPlot(true);
              } else {
                if (svgLineIndex < penPaths.get(svgPathIndex).size() - 1) {
                  sendPath();
                } else {
                    svgPathIndex++;
                    svgLineIndex = 0;
                    nextPlot(true);
                }
              }
            } else // finished
            {
                closePlot();
                float x1 = homeX;
                float y1 = homeY;

                com.sendPenUp();
                com.sendMoveG0(x1, y1);
                //com.sendMotorOff(); //<>// //<>//
                svgLineIndex = -1;
                svgPathIndex = -1;
            }
        }


        public void plot() {
            if (sh != null) {
                svgPathIndex = 0;
                svgLineIndex = 0;
                // start writing to SD card
                com.sendOpenFile();
                super.plot();
            }
        }

        public void closePlot() {
          plotting = false;
          com.sendCloseFile();
          com.sendPrintFile();
          plotDone();
          if (commeUnDesseinMode) {
            setDrawingStatusDrawn();
          }
        }

        public void rotate() {
            if (penPaths == null) return;

            for (Path p : penPaths) {
                for (int j = 0; j < p.size(); j++) {
                    float x = p.getPoint(j).x;
                    float y = p.getPoint(j).y;

                    p.getPoint(j).x = -y;
                    p.getPoint(j).y = x;
                }
            }
        }

        public void draw() {
            //println("offX: " + offX + ", offY: " + offY);
            
            lastX = -offX;
            lastY = -offY;
            strokeWeight(0.1f);
            noFill();


            for (int i = 0; i < penPaths.size(); i++) {
                Path p = penPaths.get(i);

                stroke(rapidColor);
                if (i == 0)
                    sline(homeX, homeY, p.first().x * scaleX + homeX + offX, p.first().y * scaleY + homeY + offY);
                else
                    sline(lastX * scaleX + homeX + offX, lastY * scaleY + homeY + offY, p.first().x * scaleX + homeX + offX, p.first().y * scaleY + homeY + offY);

                stroke(plotColor);
                beginShape();
                for (int j = 0; j < p.size(); j++) {
                    vertex(scaleX(p.getPoint(j).x * scaleX + homeX + offX), scaleY(p.getPoint(j).y * scaleY + homeY + offY));
                }
                endShape();
                lastX = p.last().x;
                lastY = p.last().y;
            }

            stroke(rapidColor);
            sline(lastX * scaleX + homeX + offX, lastY * scaleY + homeY + offY, homeX, homeY);

            drawPlottedLine();

        }
        
        public RShape removeContours(RShape shape) {
           RShape newShape = new RShape();
           if(shape.children != null)
           {
             for(int i=0 ; i<shape.children.length ; i++)
             {
                newShape.addChild(removeContours(shape.children[i]));
             }
           }
           
           if(shape.paths != null)
           {
             for(int i=0 ; i<shape.paths.length ; i++)
             {
                  RPath path = shape.paths[i];
                  RPoint[] points = path.getPoints();
                  RPoint previousPoint = points[0];
                  for(int j=1 ; j<points.length ; j++)
                  {
                      if(Math.abs(points[j].y-previousPoint.y)<0.1)
                      {
                        RPath newPath = new RPath(previousPoint);
                        newPath.addLineTo(points[j]);
                        newShape.addPath(newPath);
                      }
                  }
             }
           }
           return newShape;
        }

        public RShape createStripes(int stripeStep) {
        
              RShape stripes = new RShape();
              int margin = 100;
              int nStripes = int((sh.height+2*margin)/stripeStep);
              float x = sh.getTopLeft().x-margin;
              float y = sh.getTopLeft().y-margin;
              for(int i=0 ; i<nStripes ; i++)
              {
                RShape stripe = RShape.createRectangle(x, y, sh.width+2*margin, stripeStep/2);
                stripes.addChild(stripe);
                y += stripeStep;
              }
              return stripes;
        }
        
        public void setItemColor(RShape shape, String c) {
          if(shape.children != null)
           {
             for(int i=0 ; i<shape.children.length ; i++)
             {
               setItemColor(shape.children[i], c);
             }
           }
           
           if(shape.paths != null)
           {
             for(int i=0 ; i<shape.paths.length ; i++)
             {
               RStyle style = shape.paths[i].getStyle();
               
               if(style.fill && alpha(style.fillColor)>0)
               {
                  shape.paths[i].setFill(unhex(c));                 
               }
               if(style.stroke && alpha(style.strokeColor)>0)
               {
                  shape.paths[i].setStroke(unhex(c));    
                  shape.paths[i].setStrokeWeight(20);                 
               }
               
             }
           }
        }
        
        public void reduceColors(RShape shape) {
          String c = "white";
          
           for(int i=0 ; i<shape.children.length ; i++)
           {
             RShape layer = shape.children[i]; 
             println("Layer: " + layer.name);
             for(int j=0 ; j<layer.children.length ; j++)
             {
                RShape subLayer = layer.children[j]; 
                println(" - subLayer: " + subLayer.name);
                if (subLayer.name.indexOf("ROSE") != -1)
                  c = "FFECO38A";
                else if (subLayer.name.indexOf("VERT_CLAIR") != -1)
                  c = "FF8AC443";
                else if (subLayer.name.indexOf("VERT_MENTHE") != -1)
                  c = "FF22B374";
                else if (subLayer.name.indexOf("VERT_MOYEN") != -1)
                  c = "FF009F4C";
                else if (subLayer.name.indexOf("ROUGE") != -1)
                  c = "FFEC1D24";
                else if (subLayer.name.indexOf("ORANGE") != -1)
                  c = "FFF06423";
                else if (subLayer.name.indexOf("MARRON_CLAIR") != -1)
                  c = "FF895D3B";
                else if (subLayer.name.indexOf("MARRON_FONCE") != -1)
                  c = "FF5F3713";
                else if (subLayer.name.indexOf("JAUNE") != -1)
                  c = "FFFFDC23";
                else if (subLayer.name.indexOf("BLEU_FONCE") != -1)
                  c = "FF2C388D";
                else if (subLayer.name.indexOf("BLEU_CLAIR") != -1)
                  c = "FF1E75B9";
                else if (subLayer.name.indexOf("MARRON") != -1)
                  c = "FF5F3713";
                else if (subLayer.name.indexOf("VIOLET") != -1)
                  c = "FF7F3F95";
                else if (subLayer.name.indexOf("NOIR") != -1)
                  c = "FF000000";
                else
                  println("unkown color: " + subLayer.name);
                setItemColor(subLayer, c);
             }
           }
        }
        
        public void createLayers(RShape shape, RShape stripes) {
          
          RShape newShape = new RShape();
           for(int i=0 ; i<shape.children.length ; i++)
           {
             RShape subLayer = shape.children[i]; 
             for(int j=0 ; j<subLayer.children.length ; j++)
             {
                String filename = "Layer" + i + "." + j + "-" + subLayer.name + ".svg";
                RG.saveShape(filename, subLayer);
                
                RShape intersection = subLayer.intersection(stripes);
                
                RShape stipedShape = removeContours(intersection);
                stipedShape.addChild(subLayer);
                
                String filename2 = "StripedLayer" + i + "." + j + "-" + subLayer.name + ".svg";
                stipedShape.name = filename2;
                RG.saveShape(filename2, stipedShape);
                
                newShape.addChild(stipedShape);
             }
           }
           
           RG.saveShape("plantsPreview.svg", newShape);
        }
        
        public void loadAndProcess(String filename) {

            File file = new File(filename);
            if (file.exists()) { //<>// //<>//
                sh = RG.loadShape(filename);
                //reduceColors(sh);
                
                RShape stripes = createStripes(75);
                
                createLayers(sh, stripes);
                /*
                RShape intersection = sh.intersection(stripes);
                
                RShape stipedShape = removeContours(intersection);
                sh.addChild(stipedShape);
                String filenameNoExt = filename.substring(0, filename.indexOf(".svg"));
                RG.saveShape(filenameNoExt+"-striped.svg", sh);
                */
                println("loaded " + filename);
                //sh.addChild(stripes);
                optimize(sh);
                loaded = true;
            } else
                println("Failed to load file " + filename);


        }

        public void load(String filename) {
          
            File file = new File(filename);
            if (file.exists()) {
                sh = RG.loadShape(filename);
                
                //offX = -1473;
                //offY = 0;
                //userScale = 1.36;
                //updateScale();
                println("loaded " + filename);
                //optimizeOriginal(sh);
                optimize(sh);
                loaded = true;
            } else
                println("Failed to load file " + filename);

        }

        public void totalPathLength() {
            long total = 0;
            float lx = homeX;
            float ly = homeY;
            for (Path path : penPaths) {
                for (int j = 0; j < path.size(); j++) {
                    RPoint p = path.getPoint(j);
                    total += dist(lx, ly, p.x, p.y);
                    lx = p.x;
                    ly = p.y;
                }
            }
            System.out.println("total Path length " + total);
        }

        public void optimizeOriginal(RShape shape) {
          RPoint[][] pointPaths = shape.getPointsInPaths();
            penPaths = new ArrayList<Path>();
             ArrayList<Path> remainingPaths = new ArrayList<Path>();

            for (RPoint[] pointPath : pointPaths) {
                if (pointPath != null) {
                    Path path = new Path();

                    for (int j = 0; j < pointPath.length; j++) {
                        path.addPoint(pointPath[j].x, pointPath[j].y);
                    }
                    penPaths.add(path);
                }
            }

            println("Original number of paths " + remainingPaths.size());

            Path path = nearestPath(homeX, homeY, remainingPaths);
            penPaths.add(path);

            int numPaths = remainingPaths.size();
            for (int i = 0; i < numPaths; i++) {
                RPoint last = path.last();
                path = nearestPath(last.x, last.y, remainingPaths);
                penPaths.add(path);
            }

            if (shortestSegment > 0) {
                remainingPaths = penPaths;
                penPaths = new ArrayList<Path>();

                mergePaths(shortestSegment, remainingPaths);
                println("number of optimized paths " + penPaths.size());

                println("number of points " + totalPoints(penPaths));
                removeShort(shortestSegment);
                println("number of opt points " + totalPoints(penPaths));
            }
            totalPathLength();
        }
        
        public void optimize(RShape shape) {
            RPoint[][] pointPaths = shape.getPointsInPaths();
            penPaths = new ArrayList<Path>();
            // ArrayList<Path> remainingPaths = new ArrayList<Path>();

            for (RPoint[] pointPath : pointPaths) {
                if (pointPath != null) {
                    Path path = new Path();

                    for (int j = 0; j < pointPath.length; j++) {
                        path.addPoint(pointPath[j].x, pointPath[j].y);
                    }
                    penPaths.add(path);
                }
            }
            totalPathLength();

        }

        public void removeShort(float len) {
            for (Path optimizedPath : penPaths) optimizedPath.removeShort(len);
        }

        public int totalPoints(ArrayList<Path> list) {
            int total = 0;
            for (Path aList : list) {
                total += aList.size();
            }
            return total;
        }

        public void mergePaths(float len, ArrayList<Path> remainingPaths) {
            Path cur = remainingPaths.get(0);
            penPaths.add(cur);

            for (int i = 1; i < remainingPaths.size(); i++) {
                Path p = remainingPaths.get(i);
                if (dist(cur.last().x, cur.last().y, p.first().x, p.first().y) < len) {
                    cur.merge(p);
                } else {
                    penPaths.add(p);
                    cur = p;
                }
            }
        }

        public Path nearestPath(float x, float y, ArrayList<Path> remainingPaths) {
            boolean reverse = false;
            double min = Double.MAX_VALUE;
            int index = 0;
            for (int i = remainingPaths.size() - 1; i >= 0; i--) {
                Path path = remainingPaths.get(i);
                RPoint first = path.first();
                float sx = first.x;
                float sy = first.y;

                double ds = (x - sx) * (x - sx) + (y - sy) * (y - sy);
                if (ds > min) continue;

                RPoint last = path.last();
                sx = last.x;
                sy = last.y;

                double de = (x - sx) * (x - sx) + (y - sy) * (y - sy);
                double d = ds + de;
                if (d < min) {
                    reverse = de < ds;
                    min = d;
                    index = i;
                }
            }

            Path p = remainingPaths.remove(index);
            if (reverse)
                p.reverse();
            return p;
        }
    }