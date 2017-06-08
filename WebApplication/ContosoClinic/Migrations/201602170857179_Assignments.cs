namespace ContosoWebApp.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class Assignments : DbMigration
    {
        public override void Up()
        {
            CreateTable(
                "dbo.ApplicationUserPatients",
                c => new
                    {
                        ApplicationUser_Id = c.String(nullable: false, maxLength: 128),
                        Patient_CustomerID = c.Int(nullable: false),
                    })
                .PrimaryKey(t => new { t.ApplicationUser_Id, t.Patient_CustomerID })
                .ForeignKey("dbo.AspNetUsers", t => t.ApplicationUser_Id, cascadeDelete: true)
                .ForeignKey("dbo.Customers", t => t.Patient_CustomerID, cascadeDelete: true)
                .Index(t => t.ApplicationUser_Id)
                .Index(t => t.Patient_CustomerID);
            
        }
        
        public override void Down()
        {
            DropForeignKey("dbo.ApplicationUserPatients", "Patient_CustomerID", "dbo.Customers");
            DropForeignKey("dbo.ApplicationUserPatients", "ApplicationUser_Id", "dbo.AspNetUsers");
            DropIndex("dbo.ApplicationUserPatients", new[] { "Patient_CustomerID" });
            DropIndex("dbo.ApplicationUserPatients", new[] { "ApplicationUser_Id" });
            DropTable("dbo.ApplicationUserPatients");
        }
    }
}
