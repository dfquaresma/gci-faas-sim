package com.openfaas.function;

import com.openfaas.model.IResponse;
import com.openfaas.model.IRequest;
import com.openfaas.model.Response;
import java.lang.Error;
import java.awt.geom.AffineTransform;
import java.awt.image.AffineTransformOp;
import java.net.URL;
import java.util.Arrays;
import java.awt.image.BufferedImage;
import java.awt.image.WritableRaster;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.awt.image.ColorModel;
import javax.imageio.ImageIO;

public class Handler implements com.openfaas.model.IHandler {
    static boolean exit;
    static double scale;
    static byte[] binaryImage;
    private int reqCount;

    static {
        try {
            ImageIO.setUseCache(false); // We don't want to cache things out for experimento purposes.

            scale = Double.parseDouble(System.getenv("scale"));

            // Reading raw bytes of the image.
            URL u = new URL(System.getenv("image_url"));
            int contentLength = u.openConnection().getContentLength();
            binaryImage = new byte[contentLength];
            InputStream openStream = u.openStream();
            int imageSize = openStream.read(binaryImage);
            if (imageSize != contentLength) {
                throw new RuntimeException(
                        String.format("Size of the downloaded image %d is different from the content length %d",
                                imageSize, contentLength));
            }
            openStream.close();
        } catch (Exception e) {
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
            long serviceTime = ((long) (after - before)); // service time in nanoseconds
            output = Long.toString(serviceTime);
        } else {
            res.setStatusCode(500);
        }
        res.setBody(output);
        System.out.println(this.reqCount + " - HANDLER LEVEL - SERVICE TIME OF callFunction: " + output);
        this.reqCount++;
        return res;
    }

    public String callFunction() {
        String err = "";
        try {
            // This copy aims to simulate the effect of downloading the binary image from an
            // URL, but without having to deal with the variance imposed by network
            // transmission churn.
            byte[] rawCopy = Arrays.copyOf(binaryImage, binaryImage.length);
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(rawCopy));
            AffineTransform transform = AffineTransform.getScaleInstance(scale, scale);
            AffineTransformOp op = new AffineTransformOp(transform, AffineTransformOp.TYPE_BILINEAR);
            op.filter(image, null).flush();
        } catch (Exception e) {
            err = e.toString() + System.lineSeparator() + e.getCause() + System.lineSeparator() + e.getMessage();
            e.printStackTrace();

        } catch (Error e) {
            err = e.toString() + System.lineSeparator() + e.getCause() + System.lineSeparator() + e.getMessage();
            e.printStackTrace();
        }
        return err;
    }
}
