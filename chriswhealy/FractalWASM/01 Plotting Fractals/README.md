# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| | 1: Plotting Fractals | [2: Initial Implementation](/chriswhealy/FractalWASM/02%20Initial%20Implementation/)

# 1: Plotting Fractals

To create any sort of fractal image, it is necessary to repeatedly evaluate a function that takes a complex number as input and gives another complex number as output.
This output value is then fed back into the original equation and a new value is generated.

In order to calculate the colour of one pixel, we must repeat this iterative calculation hundreds, if not thousands of times.

As you can imagine, this type of coding is completely CPU-bound, and is therefore ideally suited for implementation in WebAssembly.

Very conveniently, the value of any one pixel in a fractal image is quite unrelated to the value of any neighbouring pixels; therefore, the calculation of the overall image is said to be "*embarrassingly parallel*".
That is, we can greatly improve the performance of image calculation by creating multiple, independent instances of the same program, and then sharing out the pixel claculations across these instances.

This optimisation will also be demonstrated here.

## The Mandelbrot Set

![Mandelbrot Set](/assets/chriswhealy/Mandelbrot%20Set.png)

The [Mandelbrot Set](https://en.wikipedia.org/wiki/Mandelbrot_set) is created as follows:

1. First, decide on two arbitrary limits:
   * What is the maximum number of times we will iterate the calculation before giving up?
   This value is known as as `max_iters` and a reasonable starting value is `1000`
   * Each time we iterate the calculation, we get out a complex number that might well start to grow.
   It is very important to decide how big we should allow this number to become before stopping (since in some cases, it's only going to continue growing).
   This limit is called `bailout` and is typically set to `4`
1. Using this equation:

   <img src="https://render.githubusercontent.com/render/math?math=\Large Z_{n%2b1} = Z_{n}^2 %2b c">

   Starting with <tt>Z<sub>0</sub> = 0</tt> and `c` as the coordinate value of some pixel in the image, a new value (<tt>Z<sub>1</sub></tt>) can then be derived.

   Keeping `c` the same, we now simply put the value of <tt>Z<sub>1</sub></tt> back into the equation to derive <tt>Z<sub>2</sub></tt>, then <tt>Z<sub>3</sub></tt> and <tt>Z<sub>4</sub></tt> and so on until either `|Z| > bailout` or we hit the iteration limit defined by `max_iters`
   
   We are not so much interested in what the last value of <tt>Z<sub>n</sub></tt> is; instead, we're interested in the number of times around the loop we had to go before satisfying the termination condition.

1. Colour each pixel according to the number of times the equation is iterated.
   Any pixel whose iteration count hits `max_iters` is arbitrarily coloured black.
   The other pixels can be coloured according whatever aesthetically pleasing colour scheme you choose

1. Repeat steps 2 and 3 for every pixel in the image

## Julia Sets

For every point on the Mandelbrot Set, there is a corresponding [Julia Set](https://en.wikipedia.org/wiki/Julia_set).

This means that instead of starting the above iteration with <tt>Z<sub>0</sub> = 0</tt>, we start with <tt>Z<sub>0</sub></tt> set to the coordinate value of the mouse pointer position.
As you can imagine, this means that there are an infinite number of possible Julia Sets.

The one shown below corresponds to the location (-0.755, -0.19) on the Mandelbrot Set.

![Julia Set](/assets/chriswhealy/Julia%20Set.png)
