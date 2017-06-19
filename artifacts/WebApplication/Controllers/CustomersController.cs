using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Mvc;
using ContosoWebApp.Models;

namespace ContosoWebApp.Controllers
{
    public class CustomersController : Controller
    {

        // GET: Customers
        public ActionResult Index()
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                return View(db.Customers.SqlQuery("SELECT CustomerID,FirstName,LastName,MiddleName,StreetAddress,City,ZipCode,State,BirthDate,CreditCard_Number,CreditCard_Expiration,CreditCard_Code FROM dbo.Customers").ToList());
            }
            //return View(db.Customers.ToList());
        }

        // POST: Customers/Create
        // To protect from overposting attacks, please enable the specific properties you want to bind to, for 
        // more details see http://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        //[ValidateAntiForgeryToken] REMOVED so it is easy to replay SQLi attacks
        public ActionResult Index(string search)
        {
            // IMPORTANT: This code is vulnerable to SQL injection attacks by design.
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                return View(db.Customers.SqlQuery("SELECT CustomerID,FirstName,LastName,MiddleName,StreetAddress,City,ZipCode,State,BirthDate,CreditCard_Number,CreditCard_Expiration,CreditCard_Code FROM dbo.Customers WHERE [FirstName] LIKE '%" + search + "%' OR [LastName] LIKE '%" + search + "%' OR [StreetAddress] LIKE '%" + search + "%' OR [City] LIKE '%" + search + "%' OR [State] LIKE '%" + search + "%'").ToList());
            }
        }

        // GET: Customers/Details/5
        public ActionResult Details(int? CustomerID)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                if (CustomerID == null)
                {
                    return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
                }
                Customer Customer = db.Customers.Find(CustomerID);
                if (Customer == null)
                {
                    return HttpNotFound();
                }
                return View(Customer);
            }
        }

        // GET: Customers/Create
        public ActionResult Create()
        {
            return View();
        }

        // POST: Customers/Create
        // To protect from overposting attacks, please enable the specific properties you want to bind to, for 
        // more details see http://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create([Bind(Include = "CustomerID,FirstName,LastName,MiddleName,StreetAddress,City,ZipCode,State,BirthDate,CreditCard_Number,CreditCard_Expiration,CreditCard_Code")] Customer Customer)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                if (ModelState.IsValid)
                {
                    db.Customers.Add(Customer);
                    db.SaveChanges();
                    return RedirectToAction("Index");
                }
            }

            return View(Customer);
        }

        // GET: Customers/Edit/5
        public ActionResult Edit(int? CustomerID)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                if (CustomerID == null)
                {
                    return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
                }
                Customer Customer = db.Customers.Find(CustomerID);
                if (Customer == null)
                {
                    return HttpNotFound();
                }
                return View(Customer);
            }
        }

        // POST: Customers/Edit/5
        // To protect from overposting attacks, please enable the specific properties you want to bind to, for 
        // more details see http://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "CustomerID,FirstName,LastName,MiddleName,StreetAddress,City,ZipCode,State,BirthDate,CreditCard_Number,CreditCard_Expiration,CreditCard_Code")] Customer Customer)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                if (ModelState.IsValid)
                {
                    db.Entry(Customer).State = EntityState.Modified;
                    db.SaveChanges();
                    return RedirectToAction("Index");
                }
            }
            return View(Customer);
        }

        // GET: Customers/Delete/5
        public ActionResult Delete(int? CustomerID)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                if (CustomerID == null)
                {
                    return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
                }
                Customer Customer = db.Customers.Find(CustomerID);
                if (Customer == null)
                {
                    return HttpNotFound();
                }
                return View(Customer);
            }
        }

        // POST: Customers/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int CustomerID)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                Customer Customer = db.Customers.Find(CustomerID);
                db.Customers.Remove(Customer);
                db.SaveChanges();
                return RedirectToAction("Index");
            }
        }

        protected override void Dispose(bool disposing)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                if (disposing)
                {
                    db.Dispose();
                }
                base.Dispose(disposing);
            }
        }
    }
}
