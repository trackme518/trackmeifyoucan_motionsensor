import java.util.function.BiConsumer;

import org.apache.commons.math3.distribution.NormalDistribution;
import org.apache.commons.math3.distribution.RealDistribution;
import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;

ZScore zscore;
void setup() {
  size(640, 480, P2D);
  zscore = new ZScore();
}

void draw() {
}

class ZScore {
  ZScore() {
    //ZScore program = new ZScore();
    double[] values = {9967, 11281, 10752, 10576, 2366, 11882, 11798};
    computeZScoreAndSurvivalFunctions(
      new DescriptiveStatistics(values),
      new NormalDistribution()
      );
  }

  private void computeZScoreAndSurvivalFunctions(
    DescriptiveStatistics ds,
    RealDistribution dist
    ) {
    double variance = ds.getPopulationVariance();
    double sd = Math.sqrt(variance);
    double mean = ds.getMean();

    System.out.printf("| %4s | %4s | %4s | %4s |%n", "original", "zscore", "sf", "mapped");
    System.out.printf("--------------------------------%n");

    float min = 9999999;
    float max = -9999999;

    for ( int index = 0; index < ds.getN(); ++index) {
      double zscore = (ds.getElement(index)-mean)/sd;
      if (zscore<min) {
        min = (float)zscore;
      }
      if (zscore> max) {
        max = (float)zscore;
      }

      //double sf = 1.0 - dist.cumulativeProbability(Math.abs(zscore));
      //System.out.printf("%5d | %5f | %5f | %5f | %n", (int)ds.getElement(index), zscore, sf, map((float)zscore, -3, 3, 0, 1) );
      //println("original: "+ds.getElement(index)+" zscore: "+zscore+" sf: "+sf+" mapped: "+map((float)zscore,-3,3,0,1) );
    }

    for ( int index = 0; index < ds.getN(); ++index) {
      double zscore = (ds.getElement(index)-mean)/sd;
      double sf = 1.0 - dist.cumulativeProbability(Math.abs(zscore));
      System.out.printf("%5d | %5f | %5f | %5f | %n", (int)ds.getElement(index), zscore, sf, map((float)zscore, min, max, 0, 1) );
      //println("original: "+ds.getElement(index)+" zscore: "+zscore+" sf: "+sf+" mapped: "+map((float)zscore,-3,3,0,1) );
    }
  }
}

/*

 %-10s to allocate 10 spaces for text String display. The minus signs forces left justification.
 %-8s to allocate 8 spaces for text String display. Again, the minus signs forces left justification.
 %04d, to allocate 4 spaces to display the digits. The 0 in %04d causes zero fills when a number is not 4 digits long.
 
 
 %c character
 %d decimal (integer) number (base 10)
 %e exponential floating-point number
 %f floating-point number
 %i integer (base 10)
 %o octal number (base 8)
 %s String
 %u unsigned decimal (integer) number
 %x number in hexadecimal (base 16)
 %t formats date/time
 %% print a percent sign
 \% print a percent sign
 
 
 \b backspace
 \f next line first character starts to the right of current line last character
 \n newline
 \r carriage return
 \t tab
 \\ backslash
 
 */
