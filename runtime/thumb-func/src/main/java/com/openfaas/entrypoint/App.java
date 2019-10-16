// Copyright (c) OpenFaaS Author(s) 2018. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

package com.openfaas.entrypoint;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.OutputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.InetSocketAddress;
import org.apache.log4j.Logger;

import java.util.HashMap;
import java.util.Map;
import com.sun.net.httpserver.Headers;

import com.openfaas.model.*;

public class App {

    public static void main(String[] args) throws Exception {
        int port = Integer.parseInt(System.getenv("entrypoint_port"));

        IHandler handler = new com.openfaas.function.Handler();

        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        InvokeHandler invokeHandler = new InvokeHandler(handler);

        server.createContext("/", invokeHandler);
        server.setExecutor(null); // creates a default executor
        server.start();
    }

    static class InvokeHandler implements HttpHandler {
        private static final Logger LOGGER = Logger.getLogger(InvokeHandler.class);
        private int reqCount;
        private long before;
        private long after;
        IHandler handler;

        private InvokeHandler(IHandler handler) {
            this.handler = handler;
        }

        @Override
        public void handle(HttpExchange t) throws IOException {            
            String requestBody = "";

            this.before = System.nanoTime();
            String method = t.getRequestMethod();
            this.after = System.nanoTime();
            LOGGER.info(this.reqCount + " - APP LEVEL - SERVICE TIME OF getRequestMethod: " + Float.toString(((float) (this.after - this.before)) / 1000000000));

            this.before = System.nanoTime();
            if (method.equalsIgnoreCase("POST")) {
                InputStream inputStream = t.getRequestBody();
                ByteArrayOutputStream result = new ByteArrayOutputStream();
                byte[] buffer = new byte[1024];
                int length;
                while ((length = inputStream.read(buffer)) != -1) {
                    result.write(buffer, 0, length);
                }
                // StandardCharsets.UTF_8.name() > JDK 7
                requestBody = result.toString("UTF-8");
	        }
            this.after = System.nanoTime();
            LOGGER.info(this.reqCount + " - APP LEVEL - SERVICE TIME OF POST CASE: " + Float.toString(((float) (this.after - this.before)) / 1000000000));

            // System.out.println(requestBody);
            this.before = System.nanoTime();
            Headers reqHeaders = t.getRequestHeaders();
            this.after = System.nanoTime();
            LOGGER.info(this.reqCount + " - APP LEVEL - SERVICE TIME OF getRequestHeaders: " + Float.toString(((float) (this.after - this.before)) / 1000000000));

            Map<String, String> reqHeadersMap = new HashMap<String, String>();

            this.before = System.nanoTime();
            for (Map.Entry<String, java.util.List<String>> header : reqHeaders.entrySet()) {
                java.util.List<String> headerValues = header.getValue();
                if(headerValues.size() > 0) {
                    reqHeadersMap.put(header.getKey(), headerValues.get(0));
                }
            }
            this.after = System.nanoTime();
            LOGGER.info(this.reqCount + " - APP LEVEL - SERVICE TIME OF COPYING HEADERS: " + Float.toString(((float) (this.after - this.before)) / 1000000000));

            this.before = System.nanoTime();
            IRequest req = new Request(requestBody, reqHeadersMap,t.getRequestURI().getRawQuery(), t.getRequestURI().getPath());
            this.after = System.nanoTime();
            LOGGER.info(this.reqCount + " - APP LEVEL - SERVICE TIME OF CREATING REQ: " + Float.toString(((float) (this.after - this.before)) / 1000000000));
            
            this.before = System.nanoTime();
            IResponse res = this.handler.Handle(req);
            this.after = System.nanoTime();
            LOGGER.info(this.reqCount + " - APP LEVEL - SERVICE TIME OF this.handler.Handle(req): " + Float.toString(((float) (this.after - this.before)) / 1000000000));

            this.before = System.nanoTime();
            String response = res.getBody();
            byte[] bytesOut = response.getBytes("UTF-8");
            this.after = System.nanoTime();
            LOGGER.info(this.reqCount + " - APP LEVEL - SERVICE TIME OF getBody AND getBytes: " + Float.toString(((float) (this.after - this.before)) / 1000000000));

            this.before = System.nanoTime();
            Headers responseHeaders = t.getResponseHeaders();
            String contentType = res.getContentType();
            this.after = System.nanoTime();
            LOGGER.info(this.reqCount + " - APP LEVEL - SERVICE TIME OF getResponseHeaders AND getContentType: " + Float.toString(((float) (this.after - this.before)) / 1000000000));
            
            if(contentType.length() > 0) {
                responseHeaders.set("Content-Type", contentType);
            }

            this.before = System.nanoTime();
            for(Map.Entry<String, String> entry : res.getHeaders().entrySet()) {
                responseHeaders.set(entry.getKey(), entry.getValue());
            }
            this.after = System.nanoTime();
            LOGGER.info(this.reqCount + " - APP LEVEL - SERVICE TIME OF responseHeaders.set(entry.getKey(), entry.getValue());: " + Float.toString(((float) (this.after - this.before)) / 1000000000));
           
            this.before = System.nanoTime();
            t.sendResponseHeaders(res.getStatusCode(), bytesOut.length);
            this.after = System.nanoTime();
            LOGGER.info(this.reqCount + " - APP LEVEL - SERVICE TIME OF t.sendResponseHeaders(res.getStatusCode(), bytesOut.length);: " + Float.toString(((float) (this.after - this.before)) / 1000000000));

            this.before = System.nanoTime();
            OutputStream os = t.getResponseBody();
            os.write(bytesOut);
            os.close();
            this.after = System.nanoTime();
            LOGGER.info(this.reqCount + " - APP LEVEL - SERVICE TIME OF getResponseBody, write, close: " + Float.toString(((float) (this.after - this.before)) / 1000000000));

            //System.out.println("Request / " + Integer.toString(bytesOut.length) +" bytes written.");
            this.reqCount++;
        }
    }

}
