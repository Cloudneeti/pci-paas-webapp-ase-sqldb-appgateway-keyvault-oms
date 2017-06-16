namespace ContosoWebApp.Migrations
{
    using System;
    using System.Data.Entity;
    using System.Data.Entity.Migrations;
    using System.Linq;
    using ContosoWebApp.Models;
    using Microsoft.AspNet.Identity;
    using Microsoft.AspNet.Identity.EntityFramework;
    using System.Collections.Generic;

    internal sealed class Configuration : DbMigrationsConfiguration<ContosoWebApp.Models.ApplicationDbContext>
    {
        public Configuration()
        {
            AutomaticMigrationsEnabled = false;
        }

        protected override void Seed(ContosoWebApp.Models.ApplicationDbContext context)
        {/*
            // Create test userts
            var manager = new UserManager<ApplicationUser>(
                new UserStore<ApplicationUser>(
                    new ApplicationDbContext()));

            var password = "Password!1";
            var user1 = new ApplicationUser()
            {
                UserName = string.Format("rachel@contoso.com"),
                //Customers = (from p in context.Customers where p.LastName.StartsWith("A") select p).ToList()
            };

            manager.Create(user1, string.Format(password));
            var user2 = new ApplicationUser()
            {
                UserName = string.Format("alice@contoso.com"),
                //Customers = (from p in context.Customers where p.LastName.StartsWith("B") select p).ToList()
            };
            manager.Create(user2, string.Format(password));
            context.SaveChanges();*/
            // Create Customers
            context.Customers.AddOrUpdate(p => p.CustomerID,
                 new Customer {  FirstName = "Catherine", LastName = "Abel", MiddleName = "R.", StreetAddress = "57251 Serene Blvd", City = "Van Nuys", ZipCode = "91411", State = "CA", BirthDate = new System.DateTime(1996, 9, 10) },
                 new Customer {  FirstName = "Kim", LastName = "Abercrombie", MiddleName = "", StreetAddress = "Tanger Factory", City = "Branch", ZipCode = "55056", State = "MN", BirthDate = new System.DateTime(1967, 6, 5) },
                 new Customer {  FirstName = "Frances", LastName = "Adams", MiddleName = "B.", StreetAddress = "6900 Sisk Road", City = "Modesto", ZipCode = "95354", State = "CA", BirthDate = new System.DateTime(2005, 12, 26) },
                 new Customer {  FirstName = "Jay", LastName = "Adams", MiddleName = "", StreetAddress = "Blue Ridge Mall", City = "Kansas City", ZipCode = "64106", State = "MS", BirthDate = new System.DateTime(2011, 12, 28) },
                 new Customer {  FirstName = "Robert", LastName = "Ahlering", MiddleName = "E.", StreetAddress = "6500 East Grant Road", City = "Tucson", ZipCode = "85701", State = "AZ", BirthDate = new System.DateTime(1953, 12, 1) },
                 new Customer {  FirstName = "Stanley", LastName = "Alan", MiddleName = "A.", StreetAddress = "567 Sw Mcloughlin Blvd", City = "Milwaukie", ZipCode = "97222", State = "OR", BirthDate = new System.DateTime(1967, 9, 15) },
                 new Customer {  FirstName = "Paul", LastName = "Alcorn", MiddleName = "L.", StreetAddress = "White Mountain Mall", City = "Rock Springs", ZipCode = "82901", State = "WY", BirthDate = new System.DateTime(2010, 3, 23) },
                 new Customer {  FirstName = "Mary", LastName = "Alexander", MiddleName = "", StreetAddress = "2345 West Spencer Road", City = "Lynnwood", ZipCode = "98036", State = "WA", BirthDate = new System.DateTime(1985, 2, 20) },
                 new Customer {  FirstName = "Michelle", LastName = "Alexander", MiddleName = "", StreetAddress = "22589 West Craig Road", City = "North Las Vegas", ZipCode = "89030", State = "NV", BirthDate = new System.DateTime(2009, 3, 2) },
                 new Customer {  FirstName = "Marvin", LastName = "Allen", MiddleName = "N.", StreetAddress = "First Colony Mall", City = "Sugar Land", ZipCode = "77478", State = "TX", BirthDate = new System.DateTime(1962, 12, 26) },
                 new Customer {  FirstName = "Oscar", LastName = "Alpuerto", MiddleName = "L.", StreetAddress = "Rocky Mountain Pines Outlet", City = "Loveland", ZipCode = "80537", State = "CO", BirthDate = new System.DateTime(2000, 9, 19) },
                 new Customer {  FirstName = "Ramona", LastName = "Antrim", MiddleName = "J.", StreetAddress = "998 Forest Road", City = "Saginaw", ZipCode = "48601", State = "MI", BirthDate = new System.DateTime(1991, 11, 12) },
                 new Customer {  FirstName = "Thomas", LastName = "Armstrong", MiddleName = "B.", StreetAddress = "Fox Hills", City = "Culver City", ZipCode = "90232", State = "CA", BirthDate = new System.DateTime(1964, 11, 6) },
                 new Customer {  FirstName = "John", LastName = "Arthur", MiddleName = "", StreetAddress = "2345 North Freeway", City = "Houston", ZipCode = "77003", State = "TX", BirthDate = new System.DateTime(1987, 10, 12) },
                 new Customer {  FirstName = "Chris", LastName = "Ashton", MiddleName = "", StreetAddress = "70 N.W. Plaza", City = "Saint Ann", ZipCode = "63074", State = "MS", BirthDate = new System.DateTime(1991, 7, 22) },
                 new Customer {  FirstName = "Teresa", LastName = "Atkinson", MiddleName = "", StreetAddress = "The Citadel Commerce Plaza", City = "City Of Commerce", ZipCode = "90040", State = "CA", BirthDate = new System.DateTime(1969, 6, 16) },
                 new Customer {  FirstName = "Stephen", LastName = "Ayers", MiddleName = "M.", StreetAddress = "2533 Eureka Rd.", City = "Southgate", ZipCode = "48195", State = "MI", BirthDate = new System.DateTime(1977, 2, 5) },
                 new Customer {  FirstName = "James", LastName = "Bailey", MiddleName = "B.", StreetAddress = "Southgate Mall", City = "Missoula", ZipCode = "59801", State = "MT", BirthDate = new System.DateTime(1951, 9, 22) },
                 new Customer {  FirstName = "Douglas", LastName = "Baldwin", MiddleName = "A.", StreetAddress = "Horizon Outlet Center", City = "Holland", ZipCode = "49423", State = "MI", BirthDate = new System.DateTime(1956, 10, 21) },
                 new Customer {  FirstName = "Wayne", LastName = "Banack", MiddleName = "N.", StreetAddress = "48255 I-10 E. @ Eastpoint Blvd.", City = "Baytown", ZipCode = "77520", State = "TX", BirthDate = new System.DateTime(1997, 4, 4) },
                 new Customer {  FirstName = "Robert", LastName = "Barker", MiddleName = "L.", StreetAddress = "6789 Warren Road", City = "Westland", ZipCode = "48185", State = "MI", BirthDate = new System.DateTime(1991, 4, 26) },
                 new Customer {  FirstName = "John", LastName = "Beaver", MiddleName = "A.", StreetAddress = "1318 Lasalle Street", City = "Bothell", ZipCode = "98011", State = "WA", BirthDate = new System.DateTime(2010, 9, 3) },
                 new Customer {  FirstName = "John", LastName = "Beaver", MiddleName = "A.", StreetAddress = "99300 223rd Southeast", City = "Bothell", ZipCode = "98011", State = "WA", BirthDate = new System.DateTime(1999, 9, 10) },
                 new Customer {  FirstName = "Edna", LastName = "Benson", MiddleName = "J.", StreetAddress = "Po Box 8035996", City = "Dallas", ZipCode = "75201", State = "TX", BirthDate = new System.DateTime(1963, 3, 19) },
                 new Customer {  FirstName = "Payton", LastName = "Benson", MiddleName = "P.", StreetAddress = "997000 Telegraph Rd.", City = "Southfield", ZipCode = "48034", State = "MI", BirthDate = new System.DateTime(1952, 9, 16) },
                 new Customer {  FirstName = "Robert", LastName = "Bernacchi", MiddleName = "M.", StreetAddress = "25915 140th Ave Ne", City = "Bellevue", ZipCode = "98004", State = "WA", BirthDate = new System.DateTime(2000, 4, 9) },
                 new Customer {  FirstName = "Robert", LastName = "Bernacchi", MiddleName = "M.", StreetAddress = "2681 Eagle Peak", City = "Bellevue", ZipCode = "98004", State = "WA", BirthDate = new System.DateTime(1993, 3, 13) },
                 new Customer {  FirstName = "Matthias", LastName = "Berndt", MiddleName = "", StreetAddress = "Escondido", City = "Escondido", ZipCode = "92025", State = "CA", BirthDate = new System.DateTime(1974, 5, 15) },
                 new Customer {  FirstName = "Jimmy", LastName = "Bischoff", MiddleName = "", StreetAddress = "3065 Santa Margarita Parkway", City = "Trabuco Canyon", ZipCode = "92679", State = "CA", BirthDate = new System.DateTime(2015, 10, 26) },
                 new Customer {  FirstName = "Mae", LastName = "Black", MiddleName = "M.", StreetAddress = "Redford Plaza", City = "Redford", ZipCode = "48239", State = "MI", BirthDate = new System.DateTime(1997, 1, 3) },
                 new Customer {  FirstName = "Donald", LastName = "Blanton", MiddleName = "L.", StreetAddress = "Corporate Office", City = "El Segundo", ZipCode = "90245", State = "CA", BirthDate = new System.DateTime(2015, 5, 25) },
                 new Customer {  FirstName = "Michael", LastName = "Blythe", MiddleName = "Greg", StreetAddress = "9903 Highway 6 South", City = "Houston", ZipCode = "77003", State = "TX", BirthDate = new System.DateTime(1989, 3, 4) },
                 new Customer {  FirstName = "Gabriel", LastName = "Bockenkamp", MiddleName = "L.", StreetAddress = "67 Rainer Ave S", City = "Renton", ZipCode = "98055", State = "WA", BirthDate = new System.DateTime(1976, 6, 20) },
                 new Customer {  FirstName = "Luis", LastName = "Bonifaz", MiddleName = "", StreetAddress = "72502 Eastern Ave.", City = "Bell Gardens", ZipCode = "90201", State = "CA", BirthDate = new System.DateTime(2012, 5, 14) },
                 new Customer {  FirstName = "Cory", LastName = "Booth", MiddleName = "K.", StreetAddress = "Eastern Beltway Center", City = "Las Vegas", ZipCode = "89106", State = "NV", BirthDate = new System.DateTime(1974, 2, 5) },
                 new Customer {  FirstName = "Randall", LastName = "Boseman", MiddleName = "", StreetAddress = "2500 North Stemmons Freeway", City = "Dallas", ZipCode = "75201", State = "TX", BirthDate = new System.DateTime(1999, 5, 9) },
                 new Customer {  FirstName = "Cornelius", LastName = "Brandon", MiddleName = "L.", StreetAddress = "789 West Alameda", City = "Westminster", ZipCode = "80030", State = "CO", BirthDate = new System.DateTime(1976, 2, 6) },
                 new Customer {  FirstName = "Richard", LastName = "Bready", MiddleName = "", StreetAddress = "4251 First Avenue", City = "Seattle", ZipCode = "98104", State = "WA", BirthDate = new System.DateTime(1987, 11, 2) },
                 new Customer {  FirstName = "Ted", LastName = "Bremer", MiddleName = "", StreetAddress = "Bldg. 9n/99298", City = "Redmond", ZipCode = "98052", State = "WA", BirthDate = new System.DateTime(1996, 9, 12) },
                 new Customer {  FirstName = "Alan", LastName = "Brewer", MiddleName = "", StreetAddress = "4255 East Lies Road", City = "Carol Stream", ZipCode = "60188", State = "IL", BirthDate = new System.DateTime(1997, 7, 24) },
                 new Customer {  FirstName = "Walter", LastName = "Brian", MiddleName = "J.", StreetAddress = "25136 Jefferson Blvd.", City = "Culver City", ZipCode = "90232", State = "CA", BirthDate = new System.DateTime(1970, 7, 18) },
                 new Customer {  FirstName = "Christopher", LastName = "Bright", MiddleName = "M.", StreetAddress = "Washington Square", City = "Portland", ZipCode = "97205", State = "OR", BirthDate = new System.DateTime(1988, 12, 26) },
                 new Customer {  FirstName = "Willie", LastName = "Brooks", MiddleName = "P.", StreetAddress = "Holiday Village Mall", City = "Great Falls", ZipCode = "59401", State = "MT", BirthDate = new System.DateTime(2014, 4, 28) },
                 new Customer {  FirstName = "Jo", LastName = "Brown", MiddleName = "", StreetAddress = "250000 Eight Mile Road", City = "Detroit", ZipCode = "48226", State = "MI", BirthDate = new System.DateTime(1972, 8, 12) },
                 new Customer {  FirstName = "Robert", LastName = "Brown", MiddleName = "", StreetAddress = "250880 Baur Blvd", City = "Saint Louis", ZipCode = "63103", State = "MS", BirthDate = new System.DateTime(1980, 4, 8) },
                 new Customer {  FirstName = "Steven", LastName = "Brown", MiddleName = "B.", StreetAddress = "5500 Grossmont Center Drive", City = "La Mesa", ZipCode = "91941", State = "CA", BirthDate = new System.DateTime(1965, 12, 1) },
                 new Customer {  FirstName = "Mary", LastName = "Browning", MiddleName = "K.", StreetAddress = "Noah Lane", City = "Chicago", ZipCode = "60610", State = "IL", BirthDate = new System.DateTime(1998, 7, 11) },
                 new Customer {  FirstName = "Michael", LastName = "Brundage", MiddleName = "", StreetAddress = "22555 Paseo De Las Americas", City = "San Diego", ZipCode = "92102", State = "CA", BirthDate = new System.DateTime(1990, 6, 28) },
                 new Customer {  FirstName = "Shirley", LastName = "Bruner", MiddleName = "R.", StreetAddress = "4781 Highway 95", City = "Sandpoint", ZipCode = "83864", State = "ID", BirthDate = new System.DateTime(1975, 7, 2) },
                 new Customer {  FirstName = "June", LastName = "Brunner", MiddleName = "B.", StreetAddress = "678 Eastman Ave.", City = "Midland", ZipCode = "48640", State = "MI", BirthDate = new System.DateTime(1993, 7, 1) },
                 new Customer {  FirstName = "Megan", LastName = "Burke", MiddleName = "E.", StreetAddress = "Arcadia Crossing", City = "Phoenix", ZipCode = "85004", State = "AZ", BirthDate = new System.DateTime(2008, 6, 19) },
                 new Customer {  FirstName = "Karren", LastName = "Burkhardt", MiddleName = "K.", StreetAddress = "2502 Evergreen Ste E", City = "Everett", ZipCode = "98201", State = "WA", BirthDate = new System.DateTime(2001, 2, 27) },
                 new Customer {  FirstName = "Linda", LastName = "Burnett", MiddleName = "E.", StreetAddress = "2505 Gateway Drive", City = "North Sioux City", ZipCode = "57049", State = "SD", BirthDate = new System.DateTime(1965, 12, 11) },
                 new Customer {  FirstName = "Jared", LastName = "Bustamante", MiddleName = "L.", StreetAddress = "3307 Evergreen Blvd", City = "Washougal", ZipCode = "98671", State = "WA", BirthDate = new System.DateTime(1960, 9, 19) },
                 new Customer {  FirstName = "Barbara", LastName = "Calone", MiddleName = "J.", StreetAddress = "25306 Harvey Rd.", City = "College Station", ZipCode = "77840", State = "TX", BirthDate = new System.DateTime(1990, 8, 23) },
                 new Customer {  FirstName = "Lindsey", LastName = "Camacho", MiddleName = "R.", StreetAddress = "S Sound Ctr Suite 25300", City = "Lacey", ZipCode = "98503", State = "WA", BirthDate = new System.DateTime(1995, 1, 19) },
                 new Customer {  FirstName = "Frank", LastName = "Campbell", MiddleName = "", StreetAddress = "251340 E. South St.", City = "Cerritos", ZipCode = "90703", State = "CA", BirthDate = new System.DateTime(2006, 2, 18) },
                 new Customer {  FirstName = "Henry", LastName = "Campen", MiddleName = "L.", StreetAddress = "2507 Pacific Ave S", City = "Tacoma", ZipCode = "98403", State = "WA", BirthDate = new System.DateTime(1965, 8, 24) },
                 new Customer {  FirstName = "Chris", LastName = "Cannon", MiddleName = "", StreetAddress = "Lakewood Mall", City = "Lakewood", ZipCode = "90712", State = "CA", BirthDate = new System.DateTime(2006, 6, 9) },
                 new Customer {  FirstName = "Jane", LastName = "Carmichael", MiddleName = "N.", StreetAddress = "5967 W Las Positas Blvd", City = "Pleasanton", ZipCode = "94566", State = "CA", BirthDate = new System.DateTime(1977, 4, 26) },
                 new Customer {  FirstName = "Jovita", LastName = "Carmody", MiddleName = "A.", StreetAddress = "253950 N.E. 178th Place", City = "Woodinville", ZipCode = "98072", State = "WA", BirthDate = new System.DateTime(2012, 9, 22) },
                 new Customer {  FirstName = "Rob", LastName = "Caron", MiddleName = "", StreetAddress = "Ward Parkway Center", City = "Kansas City", ZipCode = "64106", State = "MS", BirthDate = new System.DateTime(1990, 5, 21) },
                 new Customer {  FirstName = "Andy", LastName = "Carothers", MiddleName = "", StreetAddress = "566 S. Main", City = "Cedar City", ZipCode = "84720", State = "UT", BirthDate = new System.DateTime(1969, 4, 7) },
                 new Customer {  FirstName = "Donna", LastName = "Carreras", MiddleName = "F.", StreetAddress = "12345 Sterling Avenue", City = "Irving", ZipCode = "75061", State = "TX", BirthDate = new System.DateTime(2008, 9, 16) },
                 new Customer {  FirstName = "Rosmarie", LastName = "Carroll", MiddleName = "J.", StreetAddress = "39933 Mission Oaks Blvd", City = "Camarillo", ZipCode = "93010", State = "CA", BirthDate = new System.DateTime(1994, 4, 6) },
                 new Customer {  FirstName = "Raul", LastName = "Casts", MiddleName = "E.", StreetAddress = "99040 California Avenue", City = "Sand City", ZipCode = "93955", State = "CA", BirthDate = new System.DateTime(1989, 7, 13) },
                 new Customer {  FirstName = "Matthew", LastName = "Cavallari", MiddleName = "J.", StreetAddress = "North 93270 Newport Highway", City = "Spokane", ZipCode = "99202", State = "WA", BirthDate = new System.DateTime(1952, 7, 26) },
                 new Customer {  FirstName = "Andrew", LastName = "Cencini", MiddleName = "", StreetAddress = "558 S 6th St", City = "Klamath Falls", ZipCode = "97601", State = "OR", BirthDate = new System.DateTime(1991, 1, 12) },
                 new Customer {  FirstName = "Stacey", LastName = "Cereghino", MiddleName = "M.", StreetAddress = "220 Mercy Drive", City = "Garland", ZipCode = "75040", State = "TX", BirthDate = new System.DateTime(1967, 6, 3) },
                 new Customer {  FirstName = "Forrest", LastName = "Chandler", MiddleName = "J.", StreetAddress = "The Quad @ WestView", City = "Whittier", ZipCode = "90605", State = "CA", BirthDate = new System.DateTime(2002, 11, 6) },
                 new Customer {  FirstName = "Lee", LastName = "Chapla", MiddleName = "J.", StreetAddress = "99433 S. Greenbay Rd.", City = "Racine", ZipCode = "53182", State = "WI", BirthDate = new System.DateTime(1991, 6, 12) },
                 new Customer {  FirstName = "Yao-Qiang", LastName = "Cheng", MiddleName = "", StreetAddress = "25 N State St", City = "Chicago", ZipCode = "60610", State = "IL", BirthDate = new System.DateTime(1954, 5, 1) },
                 new Customer {  FirstName = "Nicky", LastName = "Chesnut", MiddleName = "E.", StreetAddress = "9920 North Telegraph Rd.", City = "Pontiac", ZipCode = "48342", State = "MI", BirthDate = new System.DateTime(1966, 4, 22) },
                 new Customer {  FirstName = "Ruth", LastName = "Choin", MiddleName = "A.", StreetAddress = "7760 N. Pan Am Expwy", City = "San Antonio", ZipCode = "78204", State = "TX", BirthDate = new System.DateTime(1963, 7, 1) },
                 new Customer {  FirstName = "Anthony", LastName = "Chor", MiddleName = "", StreetAddress = "Riverside", City = "Sherman Oaks", ZipCode = "91403", State = "CA", BirthDate = new System.DateTime(2014, 7, 27) },
                 new Customer {  FirstName = "Pei", LastName = "Chow", MiddleName = "", StreetAddress = "4660 Rodeo Road", City = "Santa Fe", ZipCode = "87501", State = "NM", BirthDate = new System.DateTime(1979, 9, 11) },
                 new Customer {  FirstName = "Jill", LastName = "Christie", MiddleName = "J.", StreetAddress = "54254 Pacific Ave.", City = "Stockton", ZipCode = "95202", State = "CA", BirthDate = new System.DateTime(2001, 11, 20) },
                 new Customer {  FirstName = "Alice", LastName = "Clark", MiddleName = "", StreetAddress = "42500 W 76th St", City = "Chicago", ZipCode = "60610", State = "IL", BirthDate = new System.DateTime(1965, 12, 6) },
                 new Customer {  FirstName = "Connie", LastName = "Coffman", MiddleName = "L.", StreetAddress = "25269 Wood Dale Rd.", City = "Wood Dale", ZipCode = "60191", State = "IL", BirthDate = new System.DateTime(1993, 10, 2) },
                 new Customer {  FirstName = "John", LastName = "Colon", MiddleName = "L.", StreetAddress = "77 Beale Street", City = "San Francisco", ZipCode = "94109", State = "CA", BirthDate = new System.DateTime(1999, 6, 6) },
                 new Customer {  FirstName = "Scott", LastName = "Colvin", MiddleName = "A.", StreetAddress = "25550 Executive Dr", City = "Elgin", ZipCode = "60120", State = "IL", BirthDate = new System.DateTime(1976, 4, 23) },
                 new Customer {  FirstName = "Scott", LastName = "Cooper", MiddleName = "", StreetAddress = "Pavillion @ Redlands", City = "Redlands", ZipCode = "92373", State = "CA", BirthDate = new System.DateTime(1952, 12, 20) },
                 new Customer {  FirstName = "Eva", LastName = "Corets", MiddleName = "", StreetAddress = "2540 Dell Range Blvd", City = "Cheyenne", ZipCode = "82001", State = "WY", BirthDate = new System.DateTime(1991, 5, 16) },
                 new Customer {  FirstName = "Marlin", LastName = "Coriell", MiddleName = "M.", StreetAddress = "99800 Tittabawasee Rd.", City = "Saginaw", ZipCode = "48601", State = "MI", BirthDate = new System.DateTime(1983, 3, 16) },
                 new Customer {  FirstName = "Jack", LastName = "Creasey", MiddleName = "", StreetAddress = "Factory Merchants", City = "Barstow", ZipCode = "92311", State = "CA", BirthDate = new System.DateTime(2004, 5, 16) },
                 new Customer {  FirstName = "Grant", LastName = "Culbertson", MiddleName = "", StreetAddress = "399700 John R. Rd.", City = "Madison Heights", ZipCode = "48071", State = "MI", BirthDate = new System.DateTime(1984, 1, 28) },
                 new Customer {  FirstName = "Scott", LastName = "Culp", MiddleName = "", StreetAddress = "750 Lakeway Dr", City = "Bellingham", ZipCode = "98225", State = "WA", BirthDate = new System.DateTime(1987, 7, 8) },
                 new Customer {  FirstName = "Conor", LastName = "Cunningham", MiddleName = "", StreetAddress = "Sports Store At Park City", City = "Park City", ZipCode = "84098", State = "UT", BirthDate = new System.DateTime(1990, 8, 12) },
                 new Customer {  FirstName = "Megan", LastName = "Davis", MiddleName = "N.", StreetAddress = "48995 Evergreen Wy.", City = "Everett", ZipCode = "98201", State = "WA", BirthDate = new System.DateTime(1983, 10, 14) },
                 new Customer {  FirstName = "Alvaro", LastName = "De Matos Miranda Filho", MiddleName = "", StreetAddress = "Mountain Square", City = "Upland", ZipCode = "91786", State = "CA", BirthDate = new System.DateTime(1962, 4, 25) },
                 new Customer {  FirstName = "Aidan", LastName = "Delaney", MiddleName = "", StreetAddress = "Corporate Office", City = "Garland", ZipCode = "75040", State = "TX", BirthDate = new System.DateTime(1953, 3, 10) },
                 new Customer {  FirstName = "Stefan", LastName = "Delmarco", MiddleName = "", StreetAddress = "Incom Sports Center", City = "Ontario", ZipCode = "91764", State = "CA", BirthDate = new System.DateTime(1963, 3, 1) },
                 new Customer {  FirstName = "Prashanth", LastName = "Desai", MiddleName = "", StreetAddress = "Sapp Road West", City = "Round Rock", ZipCode = "78664", State = "TX", BirthDate = new System.DateTime(1974, 2, 12) },
                 new Customer {  FirstName = "Bev", LastName = "Desalvo", MiddleName = "L.", StreetAddress = "7009 Sw Hall Blvd.", City = "Tigard", ZipCode = "97223", State = "OR", BirthDate = new System.DateTime(1987, 6, 21) },
                 new Customer {  FirstName = "Brenda", LastName = "Diaz", MiddleName = "", StreetAddress = "2560 E. Newlands Dr", City = "Fernley", ZipCode = "89408", State = "NV", BirthDate = new System.DateTime(1983, 4, 2) },
                 new Customer {  FirstName = "Blaine", LastName = "Dockter", MiddleName = "", StreetAddress = "99000 S. Avalon Blvd. Suite 750", City = "Carson", ZipCode = "90746", State = "CA", BirthDate = new System.DateTime(1953, 11, 5) },
                 new Customer {  FirstName = "Cindy", LastName = "Dodd", MiddleName = "M.", StreetAddress = "994 Sw Cherry Park Rd", City = "Troutdale", ZipCode = "97060", State = "OR", BirthDate = new System.DateTime(2011, 9, 10) },
                 new Customer {  FirstName = "Patricia", LastName = "Doyle", MiddleName = "", StreetAddress = "225 South 314th Street", City = "Federal Way", ZipCode = "98003", State = "WA", BirthDate = new System.DateTime(1994, 3, 8) },
                 new Customer {  FirstName = "Gerald", LastName = "Drury", MiddleName = "M.", StreetAddress = "4635 S. Harrison Blvd.", City = "Ogden", ZipCode = "84401", State = "UT", BirthDate = new System.DateTime(1962, 5, 22) },
                 new Customer {  FirstName = "Bart", LastName = "Duncan", MiddleName = "", StreetAddress = "99295 S.e. Tualatin Valley_hwy.", City = "Hillsboro", ZipCode = "97123", State = "OR", BirthDate = new System.DateTime(1982, 10, 22) },
                 new Customer {  FirstName = "Maciej", LastName = "Dusza", MiddleName = "", StreetAddress = "2564 S. Redwood Rd.", City = "Riverton", ZipCode = "84065", State = "UT", BirthDate = new System.DateTime(1964, 3, 13) },
                 new Customer {  FirstName = "Carol", LastName = "Elliott", MiddleName = "B.", StreetAddress = "25220 Airline Road", City = "Corpus Christi", ZipCode = "78404", State = "TX", BirthDate = new System.DateTime(1963, 5, 28) },
                 new Customer {  FirstName = "Shannon", LastName = "Elliott", MiddleName = "P.", StreetAddress = "Factory Stores/tucson", City = "Tucson", ZipCode = "85701", State = "AZ", BirthDate = new System.DateTime(1989, 6, 27) },
                 new Customer {  FirstName = "John", LastName = "Emory", MiddleName = "", StreetAddress = "Medford", City = "Medford", ZipCode = "97504", State = "OR", BirthDate = new System.DateTime(1998, 10, 3) },
                 new Customer {  FirstName = "Gail", LastName = "Erickson", MiddleName = "", StreetAddress = "44025 W. Empire", City = "Denby", ZipCode = "57716", State = "SD", BirthDate = new System.DateTime(1963, 12, 13) },
                 new Customer {  FirstName = "Mark", LastName = "Erickson", MiddleName = "B", StreetAddress = "Factory Stores Of America", City = "Mesa", ZipCode = "85201", State = "AZ", BirthDate = new System.DateTime(1975, 3, 1) },
                 new Customer {  FirstName = "Ann", LastName = "Evans", MiddleName = "R.", StreetAddress = "Ring Plaza", City = "Norridge", ZipCode = "60706", State = "IL", BirthDate = new System.DateTime(1963, 3, 28) },
                 new Customer {  FirstName = "John", LastName = "Evans", MiddleName = "", StreetAddress = "7709 West Virginia Avenue", City = "Phoenix", ZipCode = "85004", State = "AZ", BirthDate = new System.DateTime(2009, 12, 1) },
                 new Customer {  FirstName = "Twanna", LastName = "Evans", MiddleName = "R.", StreetAddress = "Lewis County Mall", City = "Chehalis", ZipCode = "98532", State = "WA", BirthDate = new System.DateTime(1968, 11, 4) },
                 new Customer {  FirstName = "Carolyn", LastName = "Farino", MiddleName = "", StreetAddress = "3250 South Meridian", City = "Puyallup", ZipCode = "98371", State = "WA", BirthDate = new System.DateTime(1950, 2, 12) },
                 new Customer {  FirstName = "Geri", LastName = "Farrell", MiddleName = "P.", StreetAddress = "49925 Crestview Drive N.E.", City = "Rio Rancho", ZipCode = "87124", State = "NM", BirthDate = new System.DateTime(1962, 8, 11) },
                 new Customer {  FirstName = "François", LastName = "Ferrier", MiddleName = "", StreetAddress = "Eastridge Mall", City = "Casper", ZipCode = "82601", State = "WY", BirthDate = new System.DateTime(1957, 6, 14) },
                 new Customer {  FirstName = "Kathie", LastName = "Flood", MiddleName = "", StreetAddress = "705 SE Mall Parkway", City = "Everett", ZipCode = "98201", State = "WA", BirthDate = new System.DateTime(1978, 2, 8) },
                 new Customer {  FirstName = "John", LastName = "Ford", MiddleName = "", StreetAddress = "23025 S.W. Military Rd.", City = "San Antonio", ZipCode = "78204", State = "TX", BirthDate = new System.DateTime(1987, 9, 16) },
                 new Customer {  FirstName = "Garth", LastName = "Fort", MiddleName = "", StreetAddress = "3250 Baldwin Park Blvd", City = "Baldwin Park", ZipCode = "91706", State = "CA", BirthDate = new System.DateTime(1964, 11, 25) },
                 new Customer {  FirstName = "Dorothy", LastName = "Fox", MiddleName = "J.", StreetAddress = "Lakeline Mall", City = "Cedar Park", ZipCode = "78613", State = "TX", BirthDate = new System.DateTime(1966, 9, 9) },
                 new Customer {  FirstName = "Mihail", LastName = "Frintu", MiddleName = "", StreetAddress = "Bayshore Mall", City = "Eureka", ZipCode = "95501", State = "CA", BirthDate = new System.DateTime(2013, 6, 17) },
                 new Customer {  FirstName = "Paul", LastName = "Fulton", MiddleName = "J.", StreetAddress = "Horizon Outlet Center", City = "Monroe", ZipCode = "98272", State = "MI", BirthDate = new System.DateTime(1984, 6, 11) },
                 new Customer {  FirstName = "Michael", LastName = "Galos", MiddleName = "", StreetAddress = "West Park Plaza", City = "Irvine", ZipCode = "92614", State = "CA", BirthDate = new System.DateTime(2009, 12, 14) },
                 new Customer {  FirstName = "Jon", LastName = "Ganio", MiddleName = "", StreetAddress = "3900 S. 997th St.", City = "Milwaukee", ZipCode = "53202", State = "WI", BirthDate = new System.DateTime(1975, 3, 12) },
                 new Customer {  FirstName = "Dominic", LastName = "Gash", MiddleName = "P.", StreetAddress = "5420 West 22500 South", City = "Salt Lake City", ZipCode = "84101", State = "UT", BirthDate = new System.DateTime(1969, 3, 27) },
                 new Customer {  FirstName = "Janet", LastName = "Gates", MiddleName = "M.", StreetAddress = "165 North Main", City = "Austin", ZipCode = "78701", State = "TX", BirthDate = new System.DateTime(1980, 9, 2) },
                 new Customer {  FirstName = "Janet", LastName = "Gates", MiddleName = "M.", StreetAddress = "800 Interchange Blvd.", City = "Austin", ZipCode = "78701", State = "TX", BirthDate = new System.DateTime(1970, 2, 22) },
                 new Customer {  FirstName = "Orlando", LastName = "Gee", MiddleName = "N.", StreetAddress = "2251 Elliot Avenue", City = "Seattle", ZipCode = "98104", State = "WA", BirthDate = new System.DateTime(2008, 11, 11) },
                 new Customer {  FirstName = "Darren", LastName = "Gehring", MiddleName = "", StreetAddress = "509 Nafta Boulevard", City = "Laredo", ZipCode = "78040", State = "TX", BirthDate = new System.DateTime(1966, 12, 26) },
                 new Customer {  FirstName = "Jim", LastName = "Geist", MiddleName = "", StreetAddress = "35525-9th Street Sw", City = "Puyallup", ZipCode = "98371", State = "WA", BirthDate = new System.DateTime(2009, 1, 21) },
                 new Customer {  FirstName = "Guy", LastName = "Gilbert", MiddleName = "", StreetAddress = "Vista Marketplace", City = "Alhambra", ZipCode = "91801", State = "CA", BirthDate = new System.DateTime(1982, 11, 20) },
                 new Customer {  FirstName = "Janet", LastName = "Gilliat", MiddleName = "J.", StreetAddress = "9995 West Central Entrance", City = "Duluth", ZipCode = "55802", State = "MN", BirthDate = new System.DateTime(1984, 4, 14) },
                 new Customer {  FirstName = "Mary", LastName = "Gimmi", MiddleName = "M.", StreetAddress = "5525 South Hover Road", City = "Longmont", ZipCode = "80501", State = "CO", BirthDate = new System.DateTime(1966, 4, 15) },
                 new Customer {  FirstName = "Jeanie", LastName = "Glenn", MiddleName = "R.", StreetAddress = "9909 W. Ventura Boulevard", City = "Camarillo", ZipCode = "93010", State = "CA", BirthDate = new System.DateTime(1963, 4, 13) },
                 new Customer {  FirstName = "Scott", LastName = "Gode", MiddleName = "", StreetAddress = "2583 Se 272nd St", City = "Kent", ZipCode = "98031", State = "WA", BirthDate = new System.DateTime(1950, 11, 20) },
                 new Customer {  FirstName = "Mete", LastName = "Goktepe", MiddleName = "", StreetAddress = "Hanford Mall", City = "Hanford", ZipCode = "93230", State = "CA", BirthDate = new System.DateTime(1951, 11, 5) },
                 new Customer {  FirstName = "Abigail", LastName = "Gonzalez", MiddleName = "J.", StreetAddress = "99450 Highway 59 North", City = "Humble", ZipCode = "77338", State = "TX", BirthDate = new System.DateTime(2007, 3, 10) },
                 new Customer {  FirstName = "Michael", LastName = "Graff", MiddleName = "", StreetAddress = "9700 Sisk Road", City = "Modesto", ZipCode = "95354", State = "CA", BirthDate = new System.DateTime(2002, 10, 24) },
                 new Customer {  FirstName = "Douglas", LastName = "Groncki", MiddleName = "", StreetAddress = "70259 West Sunnyview Ave", City = "Visalia", ZipCode = "93291", State = "CA", BirthDate = new System.DateTime(1974, 5, 7) },
                 new Customer {  FirstName = "Brian", LastName = "Groth", MiddleName = "", StreetAddress = "Gateway", City = "Portland", ZipCode = "97205", State = "OR", BirthDate = new System.DateTime(2008, 6, 5) },
                 new Customer {  FirstName = "Erin", LastName = "Hagens", MiddleName = "M.", StreetAddress = "25001 Montague Expressway", City = "Milpitas", ZipCode = "95035", State = "CA", BirthDate = new System.DateTime(1969, 4, 12) },
                 new Customer {  FirstName = "Betty", LastName = "Haines", MiddleName = "M.", StreetAddress = "640 South 994th St. W.", City = "Billings", ZipCode = "59101", State = "MT", BirthDate = new System.DateTime(1998, 10, 4) },
                 new Customer {  FirstName = "Jean", LastName = "Handley", MiddleName = "P.", StreetAddress = "259826 Russell Rd. South", City = "Kent", ZipCode = "98031", State = "WA", BirthDate = new System.DateTime(1993, 8, 4) },
                 new Customer {  FirstName = "Kerim", LastName = "Hanif", MiddleName = "", StreetAddress = "60025 Bollinger Canyon Road", City = "San Ramon", ZipCode = "94583", State = "CA", BirthDate = new System.DateTime(1959, 12, 20) },
                 new Customer {  FirstName = "John", LastName = "Hanson", MiddleName = "", StreetAddress = "825 W 500 S", City = "Bountiful", ZipCode = "84010", State = "UT", BirthDate = new System.DateTime(1989, 9, 23) },
                 new Customer {  FirstName = "Lucy", LastName = "Harrington", MiddleName = "", StreetAddress = "482505 Warm Springs Blvd.", City = "Fremont", ZipCode = "94536", State = "CA", BirthDate = new System.DateTime(2004, 3, 25) },
                 new Customer {  FirstName = "Keith", LastName = "Harris", MiddleName = "", StreetAddress = "3207 S Grady Way", City = "Renton", ZipCode = "98055", State = "WA", BirthDate = new System.DateTime(2003, 12, 25) },
                 new Customer {  FirstName = "Keith", LastName = "Harris", MiddleName = "", StreetAddress = "7943 Walnut Ave", City = "Renton", ZipCode = "98055", State = "WA", BirthDate = new System.DateTime(1968, 7, 3) },
                 new Customer {  FirstName = "Roger", LastName = "Harui", MiddleName = "", StreetAddress = "9927 N. Main St.", City = "Tooele", ZipCode = "84074", State = "UT", BirthDate = new System.DateTime(2015, 5, 11) },
                 new Customer {  FirstName = "Ann", LastName = "Hass", MiddleName = "T.", StreetAddress = "Medford Outlet Center", City = "Medford", ZipCode = "55049", State = "MN", BirthDate = new System.DateTime(2005, 7, 28) },
                 new Customer {  FirstName = "Valerie", LastName = "Hendricks", MiddleName = "M.", StreetAddress = "Kansas City Factory Outlet", City = "Odessa", ZipCode = "64076", State = "MS", BirthDate = new System.DateTime(1976, 10, 23) },
                 new Customer {  FirstName = "Cheryl", LastName = "Herring", MiddleName = "M.", StreetAddress = "Corp Ofc Accts Payable", City = "El Segundo", ZipCode = "90245", State = "CA", BirthDate = new System.DateTime(1980, 10, 9) },
                 new Customer {  FirstName = "Ronald", LastName = "Heymsfield", MiddleName = "K.", StreetAddress = "250775 SW Hillsdale Hwy", City = "Beaverton", ZipCode = "97005", State = "OR", BirthDate = new System.DateTime(1983, 7, 22) },
                 new Customer {  FirstName = "Mike", LastName = "Hines", MiddleName = "", StreetAddress = "25250 N 90th St", City = "Scottsdale", ZipCode = "85257", State = "AZ", BirthDate = new System.DateTime(1969, 12, 3) },
                 new Customer {  FirstName = "Matthew", LastName = "Hink", MiddleName = "", StreetAddress = "No. 60 Bellis Fair Parkway", City = "Bellingham", ZipCode = "98225", State = "WA", BirthDate = new System.DateTime(1997, 2, 15) },
                 new Customer {  FirstName = "Bob", LastName = "Hodges", MiddleName = "", StreetAddress = "Ohms Road", City = "Houston", ZipCode = "77003", State = "TX", BirthDate = new System.DateTime(2010, 8, 13) },
                 new Customer {  FirstName = "David", LastName = "Hodgson", MiddleName = "", StreetAddress = "99700 Bell Road", City = "Auburn", ZipCode = "95603", State = "CA", BirthDate = new System.DateTime(1983, 4, 13) },
                 new Customer {  FirstName = "Helge", LastName = "Hoeing", MiddleName = "", StreetAddress = "Cedar Creek Stores", City = "Mosinee", ZipCode = "54455", State = "WI", BirthDate = new System.DateTime(1988, 2, 7) },
                 new Customer {  FirstName = "Juanita", LastName = "Holman", MiddleName = "J.", StreetAddress = "Lake Elisnor Place", City = "Lake Elsinore", ZipCode = "92530", State = "CA", BirthDate = new System.DateTime(1989, 5, 13) },
                 new Customer {  FirstName = "Peter", LastName = "Houston", MiddleName = "", StreetAddress = "1200 First Ave.", City = "Joliet", ZipCode = "60433", State = "IL", BirthDate = new System.DateTime(1972, 6, 10) },
                 new Customer {  FirstName = "George", LastName = "Huckaby", MiddleName = "M.", StreetAddress = "3390 South 23rd St.", City = "Tacoma", ZipCode = "98403", State = "WA", BirthDate = new System.DateTime(2003, 5, 13) },
                 new Customer {  FirstName = "Joshua", LastName = "Huff", MiddleName = "J.", StreetAddress = "Management Mall", City = "San Antonio", ZipCode = "78204", State = "TX", BirthDate = new System.DateTime(1991, 11, 7) },
                 new Customer {  FirstName = "Phyllis", LastName = "Huntsman", MiddleName = "R.", StreetAddress = "99 Front Street", City = "Minneapolis", ZipCode = "55402", State = "MN", BirthDate = new System.DateTime(1981, 8, 27) },
                 new Customer {  FirstName = "Phyllis", LastName = "Huntsman", MiddleName = "R.", StreetAddress = "City Center", City = "Minneapolis", ZipCode = "55402", State = "MN", BirthDate = new System.DateTime(1959, 6, 28) },
                 new Customer {  FirstName = "Lawrence", LastName = "Hurkett", MiddleName = "E.", StreetAddress = "6753 Howard Hughes Parkway", City = "Las Vegas", ZipCode = "89106", State = "NV", BirthDate = new System.DateTime(1993, 10, 13) },
                 new Customer {  FirstName = "Lucio", LastName = "Iallo", MiddleName = "", StreetAddress = "Simi @ The Plaza", City = "Simi Valley", ZipCode = "93065", State = "CA", BirthDate = new System.DateTime(1959, 10, 14) },
                 new Customer {  FirstName = "Richard", LastName = "Irwin", MiddleName = "L.", StreetAddress = "99828 Routh Street, Suite 825", City = "Dallas", ZipCode = "75201", State = "TX", BirthDate = new System.DateTime(1963, 8, 5) },
                 new Customer {  FirstName = "Erik", LastName = "Ismert", MiddleName = "", StreetAddress = "4927 S Meridian Ave Ste D", City = "Puyallup", ZipCode = "98371", State = "WA", BirthDate = new System.DateTime(1968, 4, 5) },
                 new Customer {  FirstName = "Eric", LastName = "Jacobsen", MiddleName = "A.", StreetAddress = "Topanga Plaza", City = "Canoga Park", ZipCode = "91303", State = "CA", BirthDate = new System.DateTime(1957, 7, 11) },
                 new Customer {  FirstName = "Jodan", LastName = "Jacobson", MiddleName = "M.", StreetAddress = "6030 Robinson Road", City = "Jefferson City", ZipCode = "65101", State = "MS", BirthDate = new System.DateTime(1996, 2, 5) },
                 new Customer {  FirstName = "Sean", LastName = "Jacobson", MiddleName = "P.", StreetAddress = "2551 East Warner Road", City = "Gilbert", ZipCode = "85233", State = "AZ", BirthDate = new System.DateTime(1950, 11, 26) },
                 new Customer {  FirstName = "Joyce", LastName = "Jarvis", MiddleName = "", StreetAddress = "955 E. County Line Rd.", City = "Englewood", ZipCode = "80110", State = "CO", BirthDate = new System.DateTime(2011, 5, 20) },
                 new Customer {  FirstName = "Barry", LastName = "Johnson", MiddleName = "", StreetAddress = "2000 300th Street", City = "Denver", ZipCode = "80203", State = "CO", BirthDate = new System.DateTime(1991, 2, 15) },
                 new Customer {  FirstName = "Barry", LastName = "Johnson", MiddleName = "", StreetAddress = "2530 South Colorado Blvd.", City = "Denver", ZipCode = "80203", State = "CO", BirthDate = new System.DateTime(2004, 2, 5) },
                 new Customer {  FirstName = "Brian", LastName = "Johnson", MiddleName = "", StreetAddress = "625 W Jackson Blvd. Unit 2502", City = "Chicago", ZipCode = "60610", State = "IL", BirthDate = new System.DateTime(1989, 6, 10) },
                 new Customer {  FirstName = "David", LastName = "Johnson", MiddleName = "", StreetAddress = "7990 Ocean Beach Hwy.", City = "Longview", ZipCode = "98632", State = "WA", BirthDate = new System.DateTime(1965, 2, 27) },
                 new Customer {  FirstName = "Tom", LastName = "Johnston", MiddleName = "H", StreetAddress = "Belz Factory Outlet", City = "Las Vegas", ZipCode = "89106", State = "NV", BirthDate = new System.DateTime(1961, 10, 19) },
                 new Customer {  FirstName = "Jean", LastName = "Jordan", MiddleName = "", StreetAddress = "440 West Huntington Dr.", City = "Monrovia", ZipCode = "91016", State = "CA", BirthDate = new System.DateTime(1969, 10, 16) },
                 new Customer {  FirstName = "Peggy", LastName = "Justice", MiddleName = "J.", StreetAddress = "15 East Main", City = "Port Orchard", ZipCode = "98366", State = "WA", BirthDate = new System.DateTime(1981, 11, 1) },
                 new Customer {  FirstName = "Sandeep", LastName = "Kaliyath", MiddleName = "", StreetAddress = "630 N. Capitol Ave.", City = "San Jose", ZipCode = "95112", State = "CA", BirthDate = new System.DateTime(1998, 11, 3) },
                 new Customer {  FirstName = "Sandeep", LastName = "Katyal", MiddleName = "", StreetAddress = "765 Delridge Way Sw", City = "Seattle", ZipCode = "98104", State = "WA", BirthDate = new System.DateTime(1955, 1, 8) },
                 new Customer {  FirstName = "John", LastName = "Kelly", MiddleName = "", StreetAddress = "Pacific West Outlet", City = "Gilroy", ZipCode = "95020", State = "CA", BirthDate = new System.DateTime(1969, 6, 25) },
                 new Customer {  FirstName = "Robert", LastName = "Kelly", MiddleName = "", StreetAddress = "6425 Nw Loop 410", City = "San Antonio", ZipCode = "78204", State = "TX", BirthDate = new System.DateTime(1979, 9, 17) },
                 new Customer {  FirstName = "Kevin", LastName = "Kennedy", MiddleName = "", StreetAddress = "2550 Ne Sandy Blvd", City = "Portland", ZipCode = "97205", State = "OR", BirthDate = new System.DateTime(2005, 12, 16) },
                 new Customer {  FirstName = "Mitch", LastName = "Kennedy", MiddleName = "", StreetAddress = "C/O Starpak, Inc.", City = "Greeley", ZipCode = "80631", State = "CO", BirthDate = new System.DateTime(1980, 2, 28) },
                 new Customer {  FirstName = "Imtiaz", LastName = "Khan", MiddleName = "", StreetAddress = "25095 W. Florissant", City = "Ferguson", ZipCode = "63135", State = "MS", BirthDate = new System.DateTime(1971, 9, 2) },
                 new Customer {  FirstName = "Karan", LastName = "Khanna", MiddleName = "", StreetAddress = "755 W Washington Ave Ste D", City = "Sequim", ZipCode = "98382", State = "WA", BirthDate = new System.DateTime(1993, 8, 3) },
                 new Customer {  FirstName = "Anton", LastName = "Kirilov", MiddleName = "", StreetAddress = "2575 Rocky Mountain Ave.", City = "Loveland", ZipCode = "80537", State = "CO", BirthDate = new System.DateTime(1951, 5, 12) },
                 new Customer {  FirstName = "Christian", LastName = "Kleinerman", MiddleName = "", StreetAddress = "25150 El Camino Real", City = "San Bruno", ZipCode = "94066", State = "CA", BirthDate = new System.DateTime(1969, 1, 10) },
                 new Customer {  FirstName = "Andrew", LastName = "Kobylinski", MiddleName = "P.", StreetAddress = "2526a Tri-Lake Blvd Ne", City = "Kirkland", ZipCode = "98033", State = "WA", BirthDate = new System.DateTime(1999, 5, 23) },
                 new Customer {  FirstName = "Eugene", LastName = "Kogan", MiddleName = "", StreetAddress = "6756 Mowry", City = "Newark", ZipCode = "94560", State = "CA", BirthDate = new System.DateTime(1960, 7, 22) },
                 new Customer {  FirstName = "Scott", LastName = "Konersmann", MiddleName = "", StreetAddress = "52500 Liberty Way", City = "Fort Worth", ZipCode = "76102", State = "TX", BirthDate = new System.DateTime(1969, 7, 15) },
                 new Customer {  FirstName = "Joy", LastName = "Koski", MiddleName = "R.", StreetAddress = "258101 Nw Evergreen Parkway", City = "Beaverton", ZipCode = "97005", State = "OR", BirthDate = new System.DateTime(1957, 6, 15) },
                 new Customer {  FirstName = "Diane", LastName = "Krane", MiddleName = "F.", StreetAddress = "46460 West Oaks Drive", City = "Novi", ZipCode = "48375", State = "MI", BirthDate = new System.DateTime(1974, 9, 5) },
                 new Customer {  FirstName = "Kay", LastName = "Krane", MiddleName = "E.", StreetAddress = "9228 Via Del Sol", City = "Phoenix", ZipCode = "85004", State = "AZ", BirthDate = new System.DateTime(1992, 12, 27) },
                 new Customer {  FirstName = "Kay", LastName = "Krane", MiddleName = "E.", StreetAddress = "Prime Outlets", City = "Phoenix", ZipCode = "85004", State = "AZ", BirthDate = new System.DateTime(2010, 9, 14) },
                 new Customer {  FirstName = "Margaret", LastName = "Krupka", MiddleName = "T.", StreetAddress = "Great Northwestern", City = "North Bend", ZipCode = "98045", State = "WA", BirthDate = new System.DateTime(1971, 3, 9) },
                 new Customer {  FirstName = "Peter", LastName = "Kurniawan", MiddleName = "", StreetAddress = "63 W Monroe", City = "Chicago", ZipCode = "60610", State = "IL", BirthDate = new System.DateTime(2015, 11, 22) },
                 new Customer {  FirstName = "Jeffrey", LastName = "Kurtz", MiddleName = "", StreetAddress = "Receiving", City = "Fullerton", ZipCode = "92831", State = "CA", BirthDate = new System.DateTime(1990, 1, 15) },
                 new Customer {  FirstName = "Eric", LastName = "Lang", MiddleName = "", StreetAddress = "25300 Biddle Road", City = "Medford", ZipCode = "97504", State = "OR", BirthDate = new System.DateTime(1988, 2, 17) },
                 new Customer {  FirstName = "Elsa", LastName = "Leavitt", MiddleName = "", StreetAddress = "2575 West 2700 South", City = "Salt Lake City", ZipCode = "84101", State = "UT", BirthDate = new System.DateTime(1956, 9, 15) },
                 new Customer {  FirstName = "Marjorie", LastName = "Lee", MiddleName = "M.", StreetAddress = "2509 W. Frankford", City = "Carrollton", ZipCode = "75006", State = "TX", BirthDate = new System.DateTime(1990, 11, 24) },
                 new Customer {  FirstName = "Roger", LastName = "Lengel", MiddleName = "", StreetAddress = "490 Ne 4th St", City = "Renton", ZipCode = "98055", State = "WA", BirthDate = new System.DateTime(1998, 2, 22) },
                 new Customer {  FirstName = "A.", LastName = "Leonetti", MiddleName = "Francesca", StreetAddress = "5700 Legacy Dr", City = "Plano", ZipCode = "75074", State = "TX", BirthDate = new System.DateTime(1979, 4, 27) },
                 new Customer {  FirstName = "Bonnie", LastName = "Lepro", MiddleName = "B.", StreetAddress = "25600 E St Andrews Pl", City = "Santa Ana", ZipCode = "92701", State = "CA", BirthDate = new System.DateTime(1984, 11, 19) },
                 new Customer {  FirstName = "Elsie", LastName = "Lewin", MiddleName = "L.", StreetAddress = "P.O. Box 6256916", City = "Dallas", ZipCode = "75201", State = "TX", BirthDate = new System.DateTime(1980, 4, 20) },
                 new Customer {  FirstName = "George", LastName = "Li", MiddleName = "Z.", StreetAddress = "910 Main Street.", City = "Sparks", ZipCode = "89431", State = "NV", BirthDate = new System.DateTime(2001, 6, 7) },
                 new Customer {  FirstName = "Joseph", LastName = "Lique", MiddleName = "M.", StreetAddress = "257700 Ne 76th Street", City = "Redmond", ZipCode = "98052", State = "WA", BirthDate = new System.DateTime(1985, 8, 14) },
                 new Customer {  FirstName = "Paulo", LastName = "Lisboa", MiddleName = "H.", StreetAddress = "9178 Jumping St.", City = "Dallas", ZipCode = "75201", State = "TX", BirthDate = new System.DateTime(1951, 11, 23) },
                 new Customer {  FirstName = "Paulo", LastName = "Lisboa", MiddleName = "H.", StreetAddress = "Po Box 8259024", City = "Dallas", ZipCode = "75201", State = "TX", BirthDate = new System.DateTime(1971, 6, 7) },
                 new Customer {  FirstName = "David", LastName = "Liu", MiddleName = "J.", StreetAddress = "855 East Main Avenue", City = "Zeeland", ZipCode = "49464", State = "MI", BirthDate = new System.DateTime(1979, 1, 27) },
                 new Customer {  FirstName = "Jinghao", LastName = "Liu", MiddleName = "", StreetAddress = "90025 Sterling St", City = "Irving", ZipCode = "75061", State = "TX", BirthDate = new System.DateTime(1996, 4, 27) },
                 new Customer {  FirstName = "Kevin", LastName = "Liu", MiddleName = "", StreetAddress = "9992 Whipple Rd", City = "Union City", ZipCode = "94587", State = "CA", BirthDate = new System.DateTime(1982, 6, 26) },
                 new Customer {  FirstName = "Sharon", LastName = "Looney", MiddleName = "J.", StreetAddress = "74400 France Avenue South", City = "Edina", ZipCode = "55436", State = "MN", BirthDate = new System.DateTime(1979, 4, 11) },
                 new Customer {  FirstName = "Judy", LastName = "Lundahl", MiddleName = "R.", StreetAddress = "25149 Howard Dr", City = "West Chicago", ZipCode = "60185", State = "IL", BirthDate = new System.DateTime(1970, 5, 8) },
                 new Customer {  FirstName = "Denise", LastName = "Maccietto", MiddleName = "R.", StreetAddress = "Port Huron", City = "Port Huron", ZipCode = "48060", State = "MI", BirthDate = new System.DateTime(1977, 8, 8) },
                 new Customer {  FirstName = "Scott", LastName = "MacDonald", MiddleName = "", StreetAddress = "St. Louis Marketplace", City = "Saint Louis", ZipCode = "63103", State = "MS", BirthDate = new System.DateTime(1984, 11, 12) },
                 new Customer {  FirstName = "Kathy", LastName = "Marcovecchio", MiddleName = "R.", StreetAddress = "9905 Three Rivers Drive", City = "Kelso", ZipCode = "98626", State = "WA", BirthDate = new System.DateTime(1994, 4, 3) },
                 new Customer {  FirstName = "Melissa", LastName = "Marple", MiddleName = "R.", StreetAddress = "603 Gellert Blvd", City = "Daly City", ZipCode = "94015", State = "CA", BirthDate = new System.DateTime(1956, 9, 26) },
                 new Customer {  FirstName = "Frank", LastName = "Mart¡nez", MiddleName = "", StreetAddress = "870 N. 54th Ave.", City = "Chandler", ZipCode = "85225", State = "AZ", BirthDate = new System.DateTime(2003, 9, 2) },
                 new Customer {  FirstName = "Chris", LastName = "Maxwell", MiddleName = "", StreetAddress = "3025 E Waterway Blvd", City = "Shelton", ZipCode = "98584", State = "WA", BirthDate = new System.DateTime(2013, 3, 16) },
                 new Customer {  FirstName = "Sandra", LastName = "Maynard", MiddleName = "B.", StreetAddress = "9952 E. Lohman Ave.", City = "Las Cruces", ZipCode = "88001", State = "NM", BirthDate = new System.DateTime(1971, 6, 20) },
                 new Customer {  FirstName = "Walter", LastName = "Mays", MiddleName = "J.", StreetAddress = "Po Box 252525", City = "Santa Ana", ZipCode = "92701", State = "CA", BirthDate = new System.DateTime(1974, 2, 5) },
                 new Customer {  FirstName = "Lola", LastName = "McCarthy", MiddleName = "M.", StreetAddress = "1050 Oak Street", City = "Seattle", ZipCode = "98104", State = "WA", BirthDate = new System.DateTime(1986, 7, 9) },
                 new Customer {  FirstName = "Jane", LastName = "McCarty", MiddleName = "A.", StreetAddress = "409 Santa Monica Blvd.", City = "Santa Monica", ZipCode = "90401", State = "CA", BirthDate = new System.DateTime(2007, 1, 15) },
                 new Customer {  FirstName = "Yvonne", LastName = "McKay", MiddleName = "", StreetAddress = "Horizon Outlet", City = "Woodbury", ZipCode = "55125", State = "MN", BirthDate = new System.DateTime(2004, 6, 25) },
                 new Customer {  FirstName = "Nkenge", LastName = "McLin", MiddleName = "", StreetAddress = "Frontier Mall", City = "Cheyenne", ZipCode = "82001", State = "WY", BirthDate = new System.DateTime(2002, 12, 16) },
                 new Customer {  FirstName = "R. Morgan", LastName = "Mendoza", MiddleName = "L.", StreetAddress = "Johnson Creek", City = "Johnson Creek", ZipCode = "53038", State = "WI", BirthDate = new System.DateTime(2005, 3, 25) },
                 new Customer {  FirstName = "Helen", LastName = "Meyer", MiddleName = "M.", StreetAddress = "7505 Laguna Boulevard", City = "Elk Grove", ZipCode = "95624", State = "CA", BirthDate = new System.DateTime(1986, 1, 15) },
                 new Customer {  FirstName = "Dylan", LastName = "Miller", MiddleName = "", StreetAddress = "Parkway Plaza", City = "El Cajon", ZipCode = "92020", State = "CA", BirthDate = new System.DateTime(1965, 5, 7) },
                 new Customer {  FirstName = "Frank", LastName = "Miller", MiddleName = "", StreetAddress = "123 W. Lake Ave.", City = "Peoria", ZipCode = "61606", State = "IL", BirthDate = new System.DateTime(1972, 12, 23) },
                 new Customer {  FirstName = "Virginia", LastName = "Miller", MiddleName = "L.", StreetAddress = "25111 228th St Sw", City = "Bothell", ZipCode = "98011", State = "WA", BirthDate = new System.DateTime(1997, 9, 8) },
                 new Customer {  FirstName = "Virginia", LastName = "Miller", MiddleName = "L.", StreetAddress = "8713 Yosemite Ct.", City = "Bothell", ZipCode = "98011", State = "WA", BirthDate = new System.DateTime(2015, 6, 17) },
                 new Customer {  FirstName = "Neva", LastName = "Mitchell", MiddleName = "M.", StreetAddress = "2528 Meridian E", City = "Puyallup", ZipCode = "98371", State = "WA", BirthDate = new System.DateTime(2010, 8, 16) },
                 new Customer {  FirstName = "Joseph", LastName = "Mitzner", MiddleName = "P.", StreetAddress = "123 Camelia Avenue", City = "Oxnard", ZipCode = "93030", State = "CA", BirthDate = new System.DateTime(1991, 4, 16) },
                 new Customer {  FirstName = "Margaret", LastName = "Smith", MiddleName = "J.", StreetAddress = "Lewiston Mall", City = "Lewiston", ZipCode = "83501", State = "ID", BirthDate = new System.DateTime(1966, 8, 2) },
                 new Customer {  FirstName = "Laura", LastName = "Steele", MiddleName = "C.", StreetAddress = "253731 West Bell Road", City = "Surprise", ZipCode = "85374", State = "AZ", BirthDate = new System.DateTime(1954, 9, 24) },
                 new Customer {  FirstName = "Alan", LastName = "Steiner", MiddleName = "", StreetAddress = "2255 254th Avenue Se", City = "Albany", ZipCode = "97321", State = "OR", BirthDate = new System.DateTime(1969, 1, 9) },
                 new Customer {  FirstName = "Alice", LastName = "Steiner", MiddleName = "M.", StreetAddress = "Lone Star Factory", City = "La Marque", ZipCode = "77568", State = "TX", BirthDate = new System.DateTime(1950, 1, 15) },
                 new Customer {  FirstName = "Derik", LastName = "Stenerson", MiddleName = "", StreetAddress = "Factory Merchants", City = "Branson", ZipCode = "65616", State = "MS", BirthDate = new System.DateTime(1984, 4, 5) },
                 new Customer {  FirstName = "Vassar", LastName = "Stern", MiddleName = "J.", StreetAddress = "25130 South State Street", City = "Sandy", ZipCode = "84070", State = "UT", BirthDate = new System.DateTime(2005, 6, 6) },
                 new Customer {  FirstName = "Wathalee", LastName = "Steuber", MiddleName = "R.", StreetAddress = "700 Se Sunnyside Road", City = "Clackamas", ZipCode = "97015", State = "OR", BirthDate = new System.DateTime(2001, 9, 24) },
                 new Customer {  FirstName = "Liza Marie", LastName = "Stevens", MiddleName = "N.", StreetAddress = "7750 E Marching Rd", City = "Scottsdale", ZipCode = "85257", State = "AZ", BirthDate = new System.DateTime(1999, 12, 24) },
                 new Customer {  FirstName = "Robert", LastName = "Stotka", MiddleName = "B.", StreetAddress = "Sports Stores @ Tuscola", City = "Tuscola", ZipCode = "61953", State = "IL", BirthDate = new System.DateTime(1974, 4, 19) },
                 new Customer {  FirstName = "Kayla", LastName = "Stotler", MiddleName = "M.", StreetAddress = "9980 S Alma School Road", City = "Chandler", ZipCode = "85225", State = "AZ", BirthDate = new System.DateTime(1987, 5, 6) },
                 new Customer {  FirstName = "Ruth", LastName = "Suffin", MiddleName = "J.", StreetAddress = "Lancaster Mall", City = "Salem", ZipCode = "97301", State = "OR", BirthDate = new System.DateTime(2001, 10, 14) },
                 new Customer {  FirstName = "Elizabeth", LastName = "Sullivan", MiddleName = "J.", StreetAddress = "Town East Center", City = "Mesquite", ZipCode = "75149", State = "TX", BirthDate = new System.DateTime(2002, 6, 18) },
                 new Customer {  FirstName = "Michael", LastName = "Sullivan", MiddleName = "", StreetAddress = "5867 Sunrise Boulevard", City = "Citrus Heights", ZipCode = "95610", State = "CA", BirthDate = new System.DateTime(1983, 8, 27) },
                 new Customer {  FirstName = "Brad", LastName = "Sutton", MiddleName = "", StreetAddress = "Three Rivers Mall", City = "Kelso", ZipCode = "98626", State = "WA", BirthDate = new System.DateTime(2011, 12, 15) },
                 new Customer {  FirstName = "Abraham", LastName = "Swearengin", MiddleName = "L.", StreetAddress = "9920 Bridgepointe Parkway", City = "San Mateo", ZipCode = "94404", State = "CA", BirthDate = new System.DateTime(1978, 4, 26) },
                 new Customer {  FirstName = "Julie", LastName = "Taft-Rider", MiddleName = "", StreetAddress = "6996 South Lindbergh", City = "Saint Louis", ZipCode = "63103", State = "MS", BirthDate = new System.DateTime(1992, 12, 9) },
                 new Customer {  FirstName = "Clarence", LastName = "Tatman", MiddleName = "R.", StreetAddress = "San Diego Factory", City = "San Ysidro", ZipCode = "92173", State = "CA", BirthDate = new System.DateTime(1975, 10, 7) },
                 new Customer {  FirstName = "Chad", LastName = "Tedford", MiddleName = "J.", StreetAddress = "9500b E. Central Texas Expressway", City = "Killeen", ZipCode = "76541", State = "TX", BirthDate = new System.DateTime(1994, 4, 24) },
                 new Customer {  FirstName = "Vanessa", LastName = "Tench", MiddleName = "J.", StreetAddress = "2500 N Serene Blvd", City = "El Segundo", ZipCode = "90245", State = "CA", BirthDate = new System.DateTime(1951, 11, 9) },
                 new Customer {  FirstName = "Judy", LastName = "Thames", MiddleName = "J.", StreetAddress = "25102 Springwater", City = "Wenatchee", ZipCode = "98801", State = "WA", BirthDate = new System.DateTime(1989, 3, 14) },
                 new Customer {  FirstName = "Daniel", LastName = "Thompson", MiddleName = "P.", StreetAddress = "755 Nw Grandstand", City = "Issaquah", ZipCode = "98027", State = "WA", BirthDate = new System.DateTime(2010, 8, 7) },
                 new Customer {  FirstName = "Donald", LastName = "Thompson", MiddleName = "M.", StreetAddress = "25472 Marlay Ave", City = "Fontana", ZipCode = "92335", State = "CA", BirthDate = new System.DateTime(1974, 7, 22) },
                 new Customer {  FirstName = "Kendra", LastName = "Thompson", MiddleName = "N.", StreetAddress = "22571 South 2500 East", City = "Idaho Falls", ZipCode = "83402", State = "ID", BirthDate = new System.DateTime(2011, 10, 8) },
                 new Customer {  FirstName = "Diane", LastName = "Tibbott", MiddleName = "", StreetAddress = "8525 South Parker Road", City = "Parker", ZipCode = "80138", State = "CO", BirthDate = new System.DateTime(1991, 8, 15) },
                 new Customer {  FirstName = "Delia", LastName = "Toone", MiddleName = "B.", StreetAddress = "755 Columbia Ctr Blvd", City = "Kennewick", ZipCode = "99337", State = "WA", BirthDate = new System.DateTime(1983, 3, 6) },
                 new Customer {  FirstName = "Michael John", LastName = "Troyer", MiddleName = "R.", StreetAddress = "Oxnard Outlet", City = "Oxnard", ZipCode = "93030", State = "CA", BirthDate = new System.DateTime(1992, 1, 23) },
                 new Customer {  FirstName = "Christie", LastName = "Trujillo", MiddleName = "J.", StreetAddress = "One Dancing, Rr No. 25", City = "Round Rock", ZipCode = "78664", State = "TX", BirthDate = new System.DateTime(1986, 11, 24) },
                 new Customer {  FirstName = "Sairaj", LastName = "Uddin", MiddleName = "", StreetAddress = "Natomas Marketplace", City = "Sacramento", ZipCode = "95814", State = "CA", BirthDate = new System.DateTime(1975, 11, 18) },
                 new Customer {  FirstName = "Sunil", LastName = "Uppal", MiddleName = "", StreetAddress = "25500 Old Spanish Trail", City = "Houston", ZipCode = "77003", State = "TX", BirthDate = new System.DateTime(1985, 6, 24) },
                 new Customer {  FirstName = "Jessie", LastName = "Valerio", MiddleName = "E.", StreetAddress = "Mall Of Orange", City = "Orange", ZipCode = "92867", State = "CA", BirthDate = new System.DateTime(2015, 4, 9) },
                 new Customer {  FirstName = "Gregory", LastName = "Vanderbout", MiddleName = "T.", StreetAddress = "950 Gateway Street", City = "Springfield", ZipCode = "97477", State = "OR", BirthDate = new System.DateTime(2013, 7, 9) },
                 new Customer {  FirstName = "Michael", LastName = "Vanderhyde", MiddleName = "", StreetAddress = "Lincoln Square", City = "Arlington", ZipCode = "76010", State = "TX", BirthDate = new System.DateTime(1993, 2, 22) },
                 new Customer {  FirstName = "Margaret", LastName = "Vanderkamp", MiddleName = "J.", StreetAddress = "62500 Neil Road", City = "Reno", ZipCode = "89502", State = "NV", BirthDate = new System.DateTime(1976, 9, 13) },
                 new Customer {  FirstName = "Gary", LastName = "Vargas", MiddleName = "T", StreetAddress = "Stevens Creek Shopping Center", City = "San Jose", ZipCode = "95112", State = "CA", BirthDate = new System.DateTime(1991, 3, 12) },
                 new Customer {  FirstName = "Nieves", LastName = "Vargas", MiddleName = "J.", StreetAddress = "Kensington Valley Shops", City = "Howell", ZipCode = "48843", State = "MI", BirthDate = new System.DateTime(1988, 11, 2) },
                 new Customer {  FirstName = "Ranjit", LastName = "Varkey Chudukatil", MiddleName = "Rudra", StreetAddress = "455 256th St.", City = "Moline", ZipCode = "61265", State = "IL", BirthDate = new System.DateTime(1992, 5, 9) },
                 new Customer {  FirstName = "Patricia", LastName = "Vasquez", MiddleName = "M.", StreetAddress = "409 S. Main Ste. 25", City = "Ellensburg", ZipCode = "98926", State = "WA", BirthDate = new System.DateTime(2013, 9, 7) },
                 new Customer {  FirstName = "Wanda", LastName = "Vernon", MiddleName = "F.", StreetAddress = "Ontario Mills", City = "Ontario", ZipCode = "91764", State = "CA", BirthDate = new System.DateTime(2004, 9, 28) },
                 new Customer {  FirstName = "Robert", LastName = "Vessa", MiddleName = "R.", StreetAddress = "72540 Blanco Rd.", City = "San Antonio", ZipCode = "78204", State = "TX", BirthDate = new System.DateTime(1955, 2, 27) },
                 new Customer {  FirstName = "Caroline", LastName = "Vicknair", MiddleName = "A.", StreetAddress = "660 Lindbergh", City = "Saint Louis", ZipCode = "63103", State = "MS", BirthDate = new System.DateTime(2007, 9, 10) }
            );

            // Create Transactions
            context.Transactions.AddOrUpdate(
                 new Transaction { CustomerID = 1, Date = new System.DateTime(2016, 1, 10), Reason = "Headache", Treatment = "A nap" },
                 new Transaction { CustomerID = 1, Date = new System.DateTime(2016, 1, 10), Reason = "Worse headache", Treatment = "A longer nap" }
            );
            
            
            // Create test userts
            var manager = new UserManager<ApplicationUser>(
                new UserStore<ApplicationUser>(
                    new ApplicationDbContext()));

            var password = "Password!1";
            var user1 = new ApplicationUser()
            {
                UserName = string.Format("rachel@contoso.com"),
                Customers = new List<Customer>()
            };

            manager.Create(user1, string.Format(password));
            var user2 = new ApplicationUser()
            {
                UserName = string.Format("alice@contoso.com"),
                //Customers = (from p in context.Customers where p.LastName.StartsWith("B") select p).ToList()
            };
            manager.Create(user2, string.Format(password));
            context.SaveChanges();
            user1.Customers = (from p in context.Customers where p.LastName.StartsWith("B") select p).ToList();
            /*var Customer = context.Customers.Find(1);
            Customer.ApplicationUsers.Add(user1);*/

            context.SaveChanges();

        }
    }
}
