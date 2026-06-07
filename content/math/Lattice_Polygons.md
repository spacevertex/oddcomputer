---
title: "Lattice Polygons"
---
### Figure 1: An example lattice polygon
![A quadrilateral lattice polygon on a coordinate grid with four lattice vertices enclosing one interior lattice point in a mathematical analytic geometry diagram](/images/LatticePolygons/01_PicksTheorem.png "test")
A sample of a lattice polygon. The formula is called "Pick's Theorem" and in this example B=8, and I=1.  This paper is not about Pick's Theorem, but it uses the same rules for counting border points. They do not have to be verticies of the polygon, they can also be points along an edge. For fun notice that A=(8/2)+1-1=4. Try this out on several shapes if you like, but be informed that the rest of this paper will ignore the results of Pick's and do something way simpler.
### Figure 2: The Basic [4:1] Lattice Polygon
![Four by one rectangular lattice polygon on a coordinate grid showing the first example of a shape with exactly four border lattice points and one interior lattice point](/images/LatticePolygons/02_basic_square.png)
Now we turn our attention to the attempt to count all of the ways we can make a lattice polygon that has exactly 4 border points, and 1 interior point. This is an image of the first such polygon that comes to mind.
### Figure 3: Probably all [4:1] possibilities
![Five different quadrilateral arrangements on a coordinate grid, each with four border lattice points and one interior lattice point, representing the initial collection of possible [4:1] configurations](/images/LatticePolygons/03_first_finds.png)
When first confronted with this thought, I sketched out these five figures and thought there were a few more maybe.
### Figure 4: The first couple concave finds
![A quadrilateral lattice polygon on a coordinate grid illustrating another set of probable arrangements with four border lattice points and one interior lattice point in a mathematical diagram, includes two new ones which are concave](/images/LatticePolygons/04_second_finds.png)
Still using pencil and paper, had little breakthrough and found 2 more examples, which excitingly were concave, and I was fairly sure I had found the majority of the possibilities.
### Figure 5: Oops they are infinite
![A quadrilateral lattice polygon demonstrating through motion that the points can be moved and still satisfy the 4:1 constraint, so there are infinitely many](/images/LatticePolygons/Diamond_Flexible.gif)
This should have been obvious from the start, but the vertices can be shifted carefully along a line and still conform to the [4:1] rule
### Figure 6: Some have to skip vertices
![A triangular lattice polygon demonstrating through motion that the points can be moved and still satisfy the 4:1 constraint, so there are infinitely many](/images/LatticePolygons/Triangle_Flexible.gif)
What was less obvious was that demonstrations of how 'flexible' the shapes can be varied greatly. For example the basic triangle, the simplest [4:1] shape with an edge border, and which itself is a carefully flexed diamond, show the behavior that flexing the peak requires moving the interior point. Also notice that the peak has to jump 2 every time so the interior point can jump one.
### Figure 7: Some have options but are bounded
![two starbust looking figure show the all the solutions to 'what is the fourth point when three starting points are chosen](/images/LatticePolygons/two_cool_ones.png)
The style of how to get these across keeps changing, because I like drawing them and some look better static. In these two versions of the same idea, you start with three points and then figure out where the fourth has to be. If it's hard to tell each show 5 solutions that are [4:1] shapes, two green on the concave side of the starting three, and three purple on the convex side. The little + shows the interior point. Notice that continuing along the line won't get you another solution.
### Figure 8: Pick the simplest three non-collinear starting points
![starting with the three points 0,0 1,0 1,1 the infinite number of solutions are suggested by a starburst figure](/images/LatticePolygons/humble_right_angle.png)
This figure pushes the boudary of what can be show legibly by having overlapping colored polygons, but notice:
- This is as simple as three non-collinear points can get (the little pink backward capital L in the middle)
- There are three different sets of solutions
    - green on the concave side of the L
    - blue symmetrically using either side of the L
    - purple on the convex side and which has only three solutions
- Unlike in Figure 7, there are infinitely many solutions (at least for two of the solution sets)
- I didn't bother marking the interior points in this figure
### Figure 9: Another attempt to show solutions
![starting with the three points 0,0 1,0 1,1 the infinite number of solutions are suggested by a starburst figure](/images/LatticePolygons/06_ugly_stretch.png)
The same idea of having three starting points as before, but solutions mapped on a line laying parallel to two of the starting points. No attempt to draw all of the polygons. Note the one with the verticle line is just the starter pack diamond with the flexibilty shown in the animated Figure 5.
### Figure 10: What if we only had 2 starting points
![starting with two points, the origin and x,y where gcd(x,y)=1](/images/LatticePolygons/08_most_general.png)
This is a conjecture, but it seems likely that you can make a [4:1] starting with any segment that has an edge that is x,y if x and y are relatively prime. So the side touches only two lattice points. The graphs show 4 ways to solve for 23,31. The points on the graph represent the next integer up from the initial line. I don't have an algorithmic way to solve but it works for the 5 shapes shown. Try the 9,13 for yourself, graph provided.

### Thanks for reading
