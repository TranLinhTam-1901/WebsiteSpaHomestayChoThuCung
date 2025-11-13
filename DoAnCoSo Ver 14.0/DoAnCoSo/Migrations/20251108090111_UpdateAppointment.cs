using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DoAnCoSo.Migrations
{
    /// <inheritdoc />
    public partial class UpdateAppointment : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "DeletedPetId",
                table: "Appointments",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Appointments_DeletedPetId",
                table: "Appointments",
                column: "DeletedPetId");

            migrationBuilder.AddForeignKey(
                name: "FK_Appointments_DeletedPets_DeletedPetId",
                table: "Appointments",
                column: "DeletedPetId",
                principalTable: "DeletedPets",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Appointments_DeletedPets_DeletedPetId",
                table: "Appointments");

            migrationBuilder.DropIndex(
                name: "IX_Appointments_DeletedPetId",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "DeletedPetId",
                table: "Appointments");
        }
    }
}
