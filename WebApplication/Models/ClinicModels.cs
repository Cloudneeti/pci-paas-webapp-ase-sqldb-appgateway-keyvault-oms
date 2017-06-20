using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace ContosoWebApp.Models
{
    public class Customer
    {
        public Customer() { }
        public int CustomerID { get; set; }

        //[StringLength(11)]
        //[Column(TypeName = "char")]
        //[Required]
        //[Display(Name ="Customer ID")]
        //public string Customer_Id { get; set; }

        [StringLength(50)]
        public string FirstName { get; set; }

        [StringLength(50)]
        [Required]
        public string LastName { get; set; }

        [StringLength(50)]
        public string MiddleName { get; set; }

        [StringLength(50)]
        [Required]
        public string StreetAddress { get; set; }

        [StringLength(50)]
        [Required]
        public string City { get; set; }

        [StringLength(5)]
        [Column(TypeName = "char")]
        [Required]
        public string ZipCode { get; set; }

        [StringLength(2)]
        [Column(TypeName = "char")]
        [Required]
        public string State { get; set; }

        [Column(TypeName = "date")]
        [Required]
        [DataType(DataType.Date)]
        [DisplayFormat(DataFormatString = "{0:dd/MM/yyyy}", ApplyFormatInEditMode = true)]
        public System.DateTime BirthDate { get; set; }

        [StringLength(19)]
        [Column(TypeName = "char")]
        [Required]
        [RegularExpression(@"^\d{16}|\d{4}-\d{4}-\d{4}-\d{4}$", ErrorMessage = "Invalid Credit Card Number")]
        public string CreditCard_Number { get; set; }

        public string CreditCard_NumberMasked
        {
            get
            {
                return "xxxx-xxxx-xxxx-" + this.CreditCard_Number.Substring(CreditCard_Number.Length - 4);
            }
        }

        [Column(TypeName = "date")]
        [Required]
        [DataType(DataType.Date)]
        public System.DateTime CreditCard_Expiration { get; set; }

        [StringLength(4)]
        [Column(TypeName = "char")]
        [Required]
        public string CreditCard_Code { get; set; }

        public virtual ICollection<Transaction> Transactions { get; set; }
        public virtual ICollection<ApplicationUser> ApplicationUsers { get; set; }
    }

    public class Transaction
    {
        public int TransactionID { get; set; }

        [Required]
        public int CustomerID { get; set; }

        [Column(TypeName = "date")]
        [Required]
        public System.DateTime Date { get; set; }

        [StringLength(4000)]
        [Required]
        [Display(Name = "Purchase Item")]
        public string Reason { get; set; }

        [StringLength(4000)]
        [Required]
        [Display(Name = "Quantity")]
        public string Treatment { get; set; }
        [Column(TypeName = "date")]
        public Nullable<System.DateTime> FollowUpDate { get; set; }

        public virtual Customer Customer { get; set; }
    }
}