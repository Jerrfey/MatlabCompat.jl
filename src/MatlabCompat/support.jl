module Support
  # this module contains supporting functions used by MatlabCompat library

  # Copyright © 2014-2015 Vardan Andriasyan, Yauhen Yakimovich, Artur Yakimovich.
  #
  #  MIT license.
  #
  # Permission is hereby granted, free of charge, to any person
  # obtaining a copy of this software and associated documentation files (the
  # "Software"), to deal in the Software without restriction, including without
  # limitation the rights to use, copy, modify, merge, publish, distribute,
  # sublicense, and/or sell copies of the Software, and to permit persons to whom
  # the Software is furnished to do so, subject to the following conditions:
  #
  # The above copyright notice and this permission notice shall be included in all
  # copies or substantial portions of the Software.
  #
  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  # SOFTWARE.

  using Images
  using ImageView

  export mat2im
  export mat2im
  export rossetta

  function mat2im(array)
    image = grayim(array)
    return image
  end

  function im2mat(image)
    array = reinterpret(Float32, float32(image))
    return convert(Array, array)
  end

  # an m-file parser aimed at converting them as close as possible from MATLAB syntax to Julia syntax
  #using
 function rossetta(filePath...)
    # parse arguments
    if length(filePath) >= 2
      inputMfilePath = filePath[1]
      outputJlFilePath = filePath[2]
    elseif length(filePath) == 1
      inputMfilePath = filePath[1]
    else
      error("not enough input arguments for rossetta()")
    end
    # read the m-file
    mFileContents = open(readlines, inputMfilePath)

    # here we parse the MATLAB/Octave code to be compatible with Julia through MatlabCompat library
    mFileContentsParsed = mFileContents;

    for iLine = 1:size(mFileContents,1)
      # 1. substitute % by # excluding
      if ismatch(r"^(\t*|\s*)%.*", mFileContents[iLine])
        # 1a. match the simplest case when % is in the beginning of the line with any number of white spaces or tabs. If true replace the first occurance of %
        mFileContentsParsed[iLine] = replace(mFileContents[iLine], "%", "#", 1)
      elseif ismatch(r".*\'.*", mFileContents[iLine]) && ismatch(r".*%.*", mFileContents[iLine])
        # 1b. match a complex case where % may be inside of the single quotes - this % shouldn't be replaced
        println("\' and % present");
        fragmentedString = split(mFileContents[iLine], "%")
        numberOfQuotes = 0
        fragmentToComment = 0
        newLine = ""
        firstOccurance = true
        for iFragment = 1:length(fragmentedString)
          # count the quotes
          if ismatch(r"\'", fragmentedString[iFragment])
            numberOfQuotes = numberOfQuotes + length(matchall(r"\'", fragmentedString[iFragment]))
          end
          # if number of quotes is even - they are closed, we can exchange the first occurance of % with # safely
          if (iseven(numberOfQuotes) && numberOfQuotes != 0 && firstOccurance == true)
            newLine = string(newLine, fragmentedString[iFragment], "#");
            firstOccurance = false;
          # is it last fragment?
          elseif (iFragment == length(fragmentedString))
            newLine = string(newLine, fragmentedString[iFragment]);
          else
              newLine = string(newLine, fragmentedString[iFragment], "%");
          end
        end
        mFileContentsParsed[iLine] = newLine
        elseif ~ismatch(r".*\'.*", mFileContents[iLine]) && ismatch(r".*%.*", mFileContents[iLine])
          # 1c. match a case where only % symbols are present
          println("% present");
          mFileContentsParsed[iLine] = replace(mFileContents[iLine], "%", "#")
        else
          println("no comment detected");
          mFileContentsParsed[iLine] = mFileContents[iLine];
        end
        # 2. substitute all single quotes ' by double quotes "
        if ismatch(r".*\'.*", mFileContentsParsed[iLine])
          mFileContentsParsed[iLine] = replace(mFileContentsParsed[iLine], "\'", "\"");
        end
      end
    # 3. append the code array with "using ..."

    extraLines = ["#This Julia file has been generated by rossetta script of MatlabCompat library from an m-file\n\r";
                "#The code generated need further corrections by you. Execute it line by line and correct the errors.\n\r";
                "using MatlabCompat\n\r importall MatlabCompat.ImageTools\n\r importall MatlabCompat.MathTools\n\r"];
    mFileContentsParsed = vcat(extraLines,mFileContentsParsed)
    if length(filePath) >= 2
      # write the jl-file
      jlFileStream = open(outputJlFilePath, "w")
      write(jlFileStream, mFileContentsParsed);
      close(jlFileStream);
      elseif length(filePath) == 1
      return mFileContentsParsed;
    else
      return false
    end
  end
end #End of Support
