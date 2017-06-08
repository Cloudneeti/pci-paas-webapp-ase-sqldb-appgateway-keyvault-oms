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
    public class TransactionsController : Controller
    {

        // GET: Transactions
        public ActionResult Index()
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                var Transactions = db.Transactions.Include(v => v.Customer);
                return View(Transactions.ToList());
            }
        }

        // GET: Transactions/Details/5
        public ActionResult Details(int? Id)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                if (Id == null)
                {
                    return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
                }
                Transaction Transaction = db.Transactions.Find(Id);
                if (Transaction == null)
                {
                    return HttpNotFound();
                }
                return View(Transaction);
            }
        }

        // GET: Transactions/Create
        public ActionResult Create()
        {
            return View();
        }

        // POST: Transactions/Create
        // To protect from overposting attacks, please enable the specific properties you want to bind to, for 
        // more details see http://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(Transaction Transaction)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                Customer Customers = db.Customers.Where(f => f.CustomerID == Transaction.CustomerID).FirstOrDefault();
                if (Customers != null)
                {
                    Transaction.Customer = Customers;
                    Transaction.CustomerID = Customers.CustomerID;
                    db.Transactions.Add(Transaction);
                    db.SaveChanges();
                    return RedirectToAction("Index");
                }
                return View(Transaction);
            }
        }

        // GET: Transactions/Edit/5
        public ActionResult Edit(int? Id)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                if (Id == null)
                {
                    return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
                }
                Transaction Transaction = db.Transactions.Find(Id);
                if (Transaction == null)
                {
                    return HttpNotFound();
                }
                ViewBag.CustomerID = new SelectList(db.Customers, "CustomerID", "CustomerID", Transaction.CustomerID);
                return View(Transaction);
            }
        }

        // POST: Transactions/Edit/5
        // To protect from overposting attacks, please enable the specific properties you want to bind to, for 
        // more details see http://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "TransactionID,CustomerID,Date,Reason,Treatment,FollowUpDate")] Transaction Transaction)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                if (ModelState.IsValid)
                {
                    db.Entry(Transaction).State = EntityState.Modified;
                    db.SaveChanges();
                    return RedirectToAction("Index");
                }
                ViewBag.CustomerID = new SelectList(db.Customers, "CustomerID", "CustomerID", Transaction.CustomerID);
                return View(Transaction);
            }
        }

        // GET: Transactions/Delete/5
        public ActionResult Delete(int? Id)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                if (Id == null)
                {
                    return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
                }
                Transaction Transaction = db.Transactions.Find(Id);
                if (Transaction == null)
                {
                    return HttpNotFound();
                }
                return View(Transaction);
            }
        }

        // POST: Transactions/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int Id)
        {
            using (var db = new ApplicationDbContext())
            {
                // At this point the underlying store connection is closed 
                db.Database.Connection.Open();
                Transaction Transaction = db.Transactions.Find(Id);
                db.Transactions.Remove(Transaction);
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
