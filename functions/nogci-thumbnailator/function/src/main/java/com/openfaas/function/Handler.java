package com.openfaas.function;

import com.openfaas.model.IHandler;
import com.openfaas.model.IResponse;
import com.openfaas.model.IRequest;
import com.openfaas.model.Response;
import java.util.List;
import java.lang.Error;
import java.awt.geom.AffineTransform;
import java.awt.image.AffineTransformOp;
import java.net.URL;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;

public class Handler implements com.openfaas.model.IHandler {

    public IResponse Handle(IRequest req) {
        long before = System.nanoTime();
        String err = callFunction();
        long after = System.nanoTime();
        
        String output = err + System.lineSeparator();
        if (err.length() == 0) 
            output = Long.toString(after - before); // Service Time in Nanoseconds
        
        Response res = new Response();
        res.setBody(output);
        return res;
    }

    static double scale;
    static BufferedImage image;
    static {
        try {
            URL imageUrl = new URL(System.getenv("image_url"));
            scale = Double.parseDouble(System.getenv("scale"));
            image = ImageIO.read(imageUrl);
        } catch(Exception e) {
            System.err.println(e.getMessage());
        }
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