package com.openfaas.function;

import com.openfaas.model.IResponse;
import com.openfaas.model.IRequest;
import com.openfaas.model.Response;
import java.lang.Error;
import java.awt.geom.AffineTransform;
import java.awt.image.AffineTransformOp;
import java.net.URL;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;

public class Handler implements com.openfaas.model.IHandler {
    static boolean exit; 
    static double scale;
    static BufferedImage image;

    static {
        try {
            URL imageUrl = new URL(System.getenv("image_url"));
            scale = Double.parseDouble(System.getenv("scale"));
            image = ImageIO.read(imageUrl);
        } catch(Exception e) {
            e.printStackTrace();
            exit = true;
        }
    }

    public IResponse Handle(IRequest req) {
        if (exit) {
            System.exit(1);
        }
        
        long before = System.nanoTime();
        String err = callFunction();
        long after = System.nanoTime();
        
        Response res = new Response();
        String output = err + System.lineSeparator();
        if (err.length() == 0) {
            float serviceTime = ((float) Long.toString(after - before)) / 1000000000;
            output = serviceTime; // Service Time in Nanoseconds
        } else {
            res.setStatusCode(500);
        }
        res.setBody(output);
        return res;
    }

    public String callFunction() {
        String err = "";
        try {
            AffineTransform transform = AffineTransform.getScaleInstance(scale, scale); 
            AffineTransformOp op = new AffineTransformOp(transform, AffineTransformOp.TYPE_BILINEAR); 
            op.filter(image, null).flush();
        } catch (Exception e) {
            err = e.toString() + System.lineSeparator()
            		+ e.getCause() + System.lineSeparator()
            		+ e.getMessage();
            e.printStackTrace();
           
        } catch (Error e) {
            err = e.toString() + System.lineSeparator()
            		+ e.getCause() + System.lineSeparator()
            		+ e.getMessage();
            e.printStackTrace();
        }
        return err;
    }

}