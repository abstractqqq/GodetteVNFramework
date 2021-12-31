
# More Advanced Dialog Dynamics

0. How to show variable values in dialog?


    Story Reaches dialog x,
    
    prepare the string x 

    var salary:int = 

    x = "I am rich and my salary is [salary] per month."

    x = x.replace("[salary]", str(salary))

    1. write a regular expression to capture all instances of "[name_of_some_var]"
    2. I am rich and my salary is 100 per month.  
       [ salary ], salary ---> 100


    Push String in dialog x to Rich Text Label
    Display it

1. How to show dialogs character by character?
    Tween or timer? 

2. Why Timer is a better choice for most purposes? 

CPS = Character per second
40 = show 40 characters in 1 second

_ : each underscore will represent a pause of (1/cps) seconds


Original string:
Hello World ___!


Hello World (wait)(wait)(wait)!