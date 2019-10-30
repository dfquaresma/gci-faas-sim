package com.awslf;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import java.lang.management.ManagementFactory;
import java.lang.management.RuntimeMXBean;
import java.util.List;

public class FlagsLogger implements RequestHandler<Integer, String> {

  @Override
  public String handleRequest(Integer input, Context context) {
    // took from https://stackoverflow.com/questions/52199875/how-to-tune-java-garbage-collector-in-aws-lambda
    RuntimeMXBean runtimeMxBean = ManagementFactory.getRuntimeMXBean();
    List<String> arguments = runtimeMxBean.getInputArguments();
    String args = "";
    for (String arg : arguments) {
      args += arg + System.lineSeparator();
    }
    return args;
  }
}