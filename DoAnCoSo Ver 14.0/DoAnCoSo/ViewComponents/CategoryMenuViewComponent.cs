using DoAnCoSo.Repositories;
using Microsoft.AspNetCore.Mvc;


public class CategoryMenuViewComponent : ViewComponent
{

    private readonly ICategoryRepository _categoryRepository;


    public CategoryMenuViewComponent(ICategoryRepository categoryRepository)
    {
        _categoryRepository = categoryRepository;
    }


    public async Task<IViewComponentResult> InvokeAsync()
    {

        var categories = await _categoryRepository.GetAllCategoriesAsync();


        return View(categories);
    }
}