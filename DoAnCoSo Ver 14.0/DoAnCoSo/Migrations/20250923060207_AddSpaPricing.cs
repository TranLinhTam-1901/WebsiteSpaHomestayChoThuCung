using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DoAnCoSo.Migrations
{
    /// <inheritdoc />
    public partial class AddSpaPricing : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SpaPricing",
                columns: table => new
                {
                    SpaPricingId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ServiceId = table.Column<int>(type: "int", nullable: false),
                    PriceUnder5kg = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    Price5To12kg = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    Price12To25kg = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    PriceOver25kg = table.Column<decimal>(type: "decimal(18,2)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SpaPricing", x => x.SpaPricingId);
                    table.ForeignKey(
                        name: "FK_SpaPricing_Services_ServiceId",
                        column: x => x.ServiceId,
                        principalTable: "Services",
                        principalColumn: "ServiceId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SpaPricing_ServiceId",
                table: "SpaPricing",
                column: "ServiceId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SpaPricing");
        }
    }
}
