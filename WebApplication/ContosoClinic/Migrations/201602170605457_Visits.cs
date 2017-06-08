namespace ContosoWebApp.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class Transactions : DbMigration
    {
        public override void Up()
        {
            CreateTable(
                "dbo.Transactions",
                c => new
                    {
                        TransactionID = c.Int(nullable: false, identity: true),
                        CustomerID = c.Int(nullable: false),
                        Date = c.DateTime(nullable: false, storeType: "date"),
                        Reason = c.String(maxLength: 4000),
                        Treatment = c.String(maxLength: 4000),
                        FollowUpDate = c.DateTime(storeType: "date"),
                    })
                .PrimaryKey(t => t.TransactionID)
                .ForeignKey("dbo.Customers", t => t.CustomerID, cascadeDelete: true)
                .Index(t => t.CustomerID);
            
        }
        
        public override void Down()
        {
            DropForeignKey("dbo.Transactions", "CustomerID", "dbo.Customers");
            DropIndex("dbo.Transactions", new[] { "CustomerID" });
            DropTable("dbo.Transactions");
        }
    }
}
