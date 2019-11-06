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
import java.io.ByteArrayOutputStream;
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
            URL url = new URL(System.getenv("image_url"));
            int contentLength = url.openConnection().getContentLength();

            ByteArrayOutputStream output = new ByteArrayOutputStream();
            InputStream inputStream = url.openStream();
            int n = 0;
            byte[] buffer = new byte[contentLength];
            while (-1 != (n = inputStream.read(buffer))) {
                output.write(buffer, 0, n);
            }
            
            binaryImage = output.toByteArray();
            int imageSize = binaryImage.length;
            if (imageSize != contentLength) {
                throw new RuntimeException(
                        String.format("Size of the downloaded image %d is different from the content length %d",
                                imageSize, contentLength));
            }
            inputStream.close();
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
        //System.out.println(this.reqCount + " - HANDLER LEVEL - SERVICE TIME OF callFunction: " + output);
        this.reqCount++;
        return res;
    }

    public String callFunction() {
        long edenBefore = getEdenPoolMemUsage();
        long edenAfter = getEdenPoolMemUsage();
        String err = "";
        try {
            // This copy aims to simulate the effect of downloading the binary image from an
            // URL, but without having to deal with the variance imposed by network
            // transmission churn.
            System.out.println("EDEN BEFORE COPY ARRAY: " + edenBefore);
            byte[] rawCopy = Arrays.copyOf(binaryImage, binaryImage.length);
            System.out.println("EDEN AFTER COPY ARRAY: " + edenAfter);
            System.out.println("EDEN DIFF COPY ARRAY: " + (edenAfter- edenBefore));

            System.out.println("EDEN BEFORE READ BYTE ARRAY: " + edenBefore);
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(rawCopy));
            System.out.println("EDEN AFTER READ BYTE ARRAY: " + edenAfter);
            System.out.println("EDEN DIFF READ BYTE ARRAY: " + (edenAfter- edenBefore));

            System.out.println("EDEN BEFORE TRANSFORM SCALE: " + edenBefore);
            AffineTransform transform = AffineTransform.getScaleInstance(scale, scale);
            System.out.println("EDEN AFTER TRANSFORM SCALE: " + edenAfter);
            System.out.println("EDEN DIFF TRANSFORM SCALE: " + (edenAfter- edenBefore));

            System.out.println("EDEN BEFORE TRANSFORM OP: " + edenBefore);
            AffineTransformOp op = new AffineTransformOp(transform, AffineTransformOp.TYPE_BILINEAR);
            System.out.println("EDEN AFTER TRANSFORM OP: " + edenAfter);
            System.out.println("EDEN DIFF TRANSFORM OP: " + (edenAfter- edenBefore));

            System.out.println("EDEN BEFORE FILTER AND FLUSH: " + edenBefore);
            op.filter(image, null).flush();
            System.out.println("EDEN AFTER FILTER AND FLUSH: " + edenAfter);
            System.out.println("EDEN DIFF FILTER AND FLUSH: " + (edenAfter- edenBefore));

        } catch (Exception e) {
            err = e.toString() + System.lineSeparator() + e.getCause() + System.lineSeparator() + e.getMessage();
            e.printStackTrace();

        } catch (Error e) {
            err = e.toString() + System.lineSeparator() + e.getCause() + System.lineSeparator() + e.getMessage();
            e.printStackTrace();
        }
        return err;
    }

    private static long getEdenPoolMemUsage() {
        for (final MemoryPoolMXBean pool : ManagementFactory.getMemoryPoolMXBeans()) {
            if (pool.getName().contains("Eden")) {
                return pool.getUsage().getUsed();
            }
        }
        return -1;
    }
}
