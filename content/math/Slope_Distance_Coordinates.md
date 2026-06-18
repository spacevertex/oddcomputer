---
title: "Slope Distance Coordinates"
---
### Figure 1: md coordinate system
![A quadrilateral lattice polygon on a coordinate grid with four lattice vertices enclosing one interior lattice point in a mathematical analytic geometry diagram](/images/LatticePolygons/01_PicksTheorem.png "test")
Coordinate system that locates a point by the slope of the line that would intersect it and the origin (m), and its distance from the origin (d). This is not much different from polar, just slope instead of angle. Easy to transform to x,y: m = y/x, d = sqrt(x^2 + y^2).  
### Figure 2: How to convice Geogebra to make these graphs for me
![Four by one rectangular lattice polygon on a coordinate grid showing the first example of a shape with exactly four border lattice points and one interior lattice point](/images/LatticePolygons/02_basic_square.png)
To get Geogebra to graph these things, all you have to do is run a parameter from -infinity to infinity, and graph the results. Easy.
### Figure 3: Maybe let's just try -100 to 100
![Five different quadrilateral arrangements on a coordinate grid, each with four border lattice points and one interior lattice point, representing the initial collection of possible [4:1] configurations](/images/LatticePolygons/03_first_finds.png)
When first confronted with this thought, I sketched out these five figures and thought there were a few more maybe.
### Figure 4: Some Graphs
![A quadrilateral lattice polygon on a coordinate grid illustrating another set of probable arrangements with four border lattice points and one interior lattice point in a mathematical diagram, includes two new ones which are concave](/images/LatticePolygons/04_second_finds.png)
Start with something simple, d = m + 5. This is obviously a very cool graph.
### Figure 5: Trigonometric functions look better when pushed away from the origin
![A quadrilateral lattice polygon demonstrating through motion that the points can be moved and still satisfy the 4:1 constraint, so there are infinitely many](/images/LatticePolygons/Diamond_Flexible.gif)
```
d = 2 + sin(5m)
```
This graph shows how more and more information is displayed as m -> infinity. 
### Figure 6: Polynomials make knots
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
The same idea of having three starting points as before, but solutions mapped on a line laying parallel to two of the starting points. No attempt to draw all of the polygons. Note the one with the verticle line is just the starter pack diamond with the flexibility shown in the animated Figure 5.
### Figure 10: What if we only had 2 starting points
![starting with two points, the origin and x,y where gcd(x,y)=1](/images/LatticePolygons/08_most_general.png)
This is a conjecture, but it seems likely that you can make a [4:1] starting with any segment that has an edge that is x,y if x and y are relatively prime. So the side touches only two lattice points. The graphs show 4 ways to solve for 23,31. The points on the graph represent the next integer up from the initial line. I don't have an algorithmic way to solve but it works for the 5 shapes shown. Try the 9,13 for yourself, graph provided.
### Figure 11: Bonus figure - a picture of some [3:1] shapes
![a double wedge shape of som [3:1] lattice polygons](/images/LatticePolygons/many_3_1.png)
My original idea was to plot how many of each combination of B and I existed. For example, [3:5]->0, there are no shapes with 3 borders and 5 interiors. Except there are, and they are just as interesting as the [4:1] stuff. I don't think there are any combinations that aren't either zero or infinitely many solutions. Find some for yourself, it's another rabbit hole. As a parting thought, Figure 11 shows a few [3,1].