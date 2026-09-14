# Transform data using dbt Jobs in Microsoft Fabric Warehouse

**90-minute hands-on lab**

The environment is prepared before the session. Each assigned workspace already contains:

- Warehouse: `sales_warehouse`
- dbt Job: `sales_dbt_job`

## Participant assignment

Use the same three-digit suffix:

- `dbt-user-001` → `dbt-fabric-ws-001`
- `dbt-user-002` → `dbt-fabric-ws-002`

Use only the workspace matching your assigned user number.

## Lab flow

Sign in → verify prepared items → load seed data → configure dbt Job → **import prepared project** → run → DAG → test → schedule → verify → semantic model.

You will start with raw sales data in a Fabric Warehouse, use a dbt Job to transform it into analytics-ready models, and then expose those models through a semantic model. Each exercise builds on the previous one, so complete the data-loading and dbt configuration steps before running the project.

## Exercise 1: Sign in and open your workspace

**Context:** Each participant has a dedicated Fabric account and workspace so that everyone can complete the lab independently. In this exercise, you will sign in, update the temporary password if prompted, and confirm that you can access the workspace matching your assigned account number.

1. Open the instructor-provided [Microsoft Fabric portal](https://fabric.microsoft.com) in an incognito or private browser window. This keeps your lab account separate from any existing Microsoft account sessions.
2. Sign in with the assigned account.
	![Sign in to the Microsoft Fabric portal](Images/login.png?v=2)
3. Enter the assigned password and select **Sign in**. If prompted, update the temporary password before continuing.
    ![Update the temporary account password](Images/update_password.png?v=2)
4. If the Fabric welcome tour appears, close it. Completing the tour is optional and is not required for this lab.
5. Select **Workspaces** in the left navigation to find the workspace assigned to you. The three-digit suffix in the workspace name matches your assigned account. For example, `dbt-test-002` uses `dbt-fabric-test-ws-002`.
    ![Open the Workspaces list in Fabric](Images/view_workspaces.png?v=2)

**Success:** You can see a workspace created for you to begin the lab.

## Exercise 2: Verify prepared items

**Context:** Your workspace has been pre-provisioned with the Fabric items needed for the lab. You will confirm that the Warehouse used to store the data and the dbt Job used to transform it are available before making any changes.

1. Click on the workspace name. You will be directed to workspace view.
    ![View the assigned Fabric workspace](Images/workspace_view.png?v=2)
2. Confirm that you see two items are present in the list - `sales_warehouse` and `sales_dbt_job` .
2. Click on `sales_warehouse` to open the warehouse.
    ![Open the sales warehouse](Images/open_warehouse.png?v=2)

**Success:** The Warehouse opens successfully.

## Exercise 3: Create seed tables

**Context:** The dbt models need source tables to read from. In this exercise, you will create a `seed` schema and the `customers`, `products`, and `orders` tables that represent the raw operational data used throughout the lab.

1. Click on New SQL Query to open the query editor.
    ![Create a new SQL query](Images/new_sql_query.png?v=2)
2. Copy-paste SQL statements in [`sql/01_create_seed_tables.sql`](sql/01_create_seed_tables.sql) and in SQL editor.
    ![Paste the seed table creation SQL](Images/cp_paste_create_seed_tables.png?v=2)
3. Click on run and all statements will be executed successfully.
    ![Run the seed table creation SQL](Images/run_seed_tables.png?v=2)
4. Expand folder Schemas -> seed -> Tables folders to view created seed tables in the object explorer.

    ![View the seed tables in Object Explorer](Images/view_seed_tables_in_oe.png?v=2)

**Success:** Schema `seed` contains `customers`, `products`, and `orders`.

## Exercise 4: Load seed data

**Context:** The tables created in the previous exercise are empty. You will load a small, known dataset so that the dbt transformations and tests produce predictable results that are easy to inspect during the lab. dbt can also load small CSV datasets included in a project by using the `dbt seed` command. Seed data is useful for demonstrations, reference data, and testing, but in most real-world scenarios your dbt models will transform data already loaded from operational systems rather than use seed data as their primary source.

1. Copy the SQL from [`sql/02_load_seed_data.sql`](sql/02_load_seed_data.sql), paste it into a new SQL query, and select **Run**.
    ![Execute the seed data SQL](Images/execute_seed_data.png?v=2)
2. Run the following query to confirm the expected number of rows was loaded:

    ```sql
    SELECT 'customers' AS table_name, COUNT(*) AS row_count
    FROM seed.customers
    UNION ALL
    SELECT 'products', COUNT(*)
    FROM seed.products
    UNION ALL
    SELECT 'orders', COUNT(*)
    FROM seed.orders;
    ```

    ![Verify the loaded seed data](Images/view_seed_data.png?v=2)

3. Inspect the contents of each source table. You can run each `SELECT` statement individually to review one result at a time, or run all three statements together and review each result set.

    ```sql
    SELECT *
    FROM seed.customers
    ORDER BY customer_id;

    SELECT *
    FROM seed.products
    ORDER BY product_id;

    SELECT *
    FROM seed.orders
    ORDER BY order_id;
    ```

    Notice that `orders` contains customer and product IDs, but not their descriptive names or the product price. These raw tables are intentionally simple; the dbt project will clean, join, and organize this data into analytics-ready models.

4. Run this query to preview the business information that can be derived by joining the raw tables:

    ```sql
    SELECT
        o.order_id,
        o.order_date,
        c.customer_name,
        p.product_name,
        p.category,
        o.quantity,
        p.unit_price,
        o.quantity * p.unit_price AS sales_amount
    FROM seed.orders AS o
    INNER JOIN seed.customers AS c
        ON o.customer_id = c.customer_id
    INNER JOIN seed.products AS p
        ON o.product_id = p.product_id
    ORDER BY o.order_id;
    ```

    Inspect a few rows and note how `sales_amount` is calculated. Later, you will compare this raw-data query with the `fct_sales` model produced by dbt.

**Success:** You can see 5 customers, 5 products, and 10 orders, and you understand how the raw tables relate to one another.

## Exercise 5: Configure the prepared dbt Job

**Context:** A dbt Job needs an adapter profile that tells dbt where to execute SQL and create models. You will connect `sales_dbt_job` to `sales_warehouse` so that the imported project can read the seed tables and materialize its transformed models in the same Warehouse.

1. Select **Workspaces** in the left navigation. This page may show only the workspace names. Select the workspace whose three-digit suffix matches your assigned account.
    ![Return to the Fabric workspace page](Images/workspace_page.png?v=2)
2. After the workspace opens, select `sales_dbt_job` from the item list. For example, a participant using `dbt-test-002` first opens `dbt-fabric-test-ws-002` and then opens `sales_dbt_job`.
    ![Open the prepared dbt job item](Images/open_dbt_job_item.png?v=2)
    This opens `sales_dbt_job` item.
    ![Open the prepared dbt job item](Images/new_dbt_item.png?v=2)
3. Select **Configure adapter settings** in the blue banner at the top of the dbt Job page. The adapter profile tells dbt which Fabric data store it should connect to when it reads source data, executes SQL, and creates transformed models.
    ![Configure the dbt adapter profile](Images/dbt-profile-select.png?v=2)
4. In the OneLake catalog, select `sales_warehouse`, and then select **Next**. This connects the dbt Job to the same Warehouse where you created and loaded the `seed` tables.
    ![Select the warehouse from the OneLake catalog](Images/choose_profile_from_ol.png?v=2)
5. Enter `jaffle_shop` as the schema name, and then select **Apply**. Use this exact schema name for the lab. Do not substitute another schema name or change it during later exercises, because the project configuration and verification queries expect dbt to create the transformed models in the generated `jaffle_shop_dbo` schema.
    ![Apply the dbt warehouse profile](Images/apply_profile.png?v=2)
6. Select **Adapter settings** in the ribbon. Confirm that the connection shows `sales_warehouse` as the target and `jaffle_shop` as the schema. Seeing these values in Adapter settings confirms that the Warehouse connection is configured successfully.
    ![Open dbt adapter settings](Images/adapter_settings.png?v=2)

> **Important:** Keep the adapter schema set to `jaffle_shop` for the remainder of the lab. The dbt project uses this target to create its models in `jaffle_shop_dbo`. Project validation in Exercises 6–8 and the `dbt build` in Exercise 9 provide an additional end-to-end check by reading the seed tables and creating the transformed models.

**Success:** Adapter settings show a connection to `sales_warehouse` with `jaffle_shop` as the target schema.

## Default path for Exercises 6–8: Import the prepared project

**Recommended for the 90-minute lab.**

**Context:** Exercises 6–8 bring a prepared dbt project into Fabric and validate its structure. The project defines sources for the seed tables, staging models that clean the raw data, mart models that organize it for analytics, and tests that check data quality. Importing the prepared project keeps the lab focused on running and understanding the Fabric dbt workflow rather than typing every project file manually.

1. Download `fabric-dbt-hol-project.zip` file at root of the github repository to your machine.
2. In `sales_dbt_job`, click on import a project tile.
    ![Import a project into the dbt job](Images/import_project.png?v=2)
3. Upload the zip file, downloaded in step 1.
4. After the ZIP file is uploaded, confirm that the following files and folders appear in the project explorer. Open each area briefly and use this checklist to understand its purpose:

    - **`dbt_project.yml`** — Defines the dbt project name, model paths, and project-level configuration. Confirm that this file is at the project root.
    ![dbt_project.yml](Images/dbt_project.png?v=2)
    - **`models/staging/sources.yml`** — Declares the `customers`, `products`, and `orders` source tables in the Warehouse `seed` schema. This is how dbt knows where the raw data is located.
    ![dbt_project.yml](Images/sources.png?v=2)
    - **`models/staging/`** — Contains the staging models that select from the source tables and prepare consistent, reusable data for downstream models. Confirm that `stg_customers.sql`, `stg_products.sql`, and `stg_orders.sql` are present.

        ![staging_models](Images/staging_models.png?v=2)
    - **`models/marts/`** — Contains the analytics-ready business models created from the staging layer. Confirm that `dim_customer.sql`, `dim_product.sql`, and `fct_sales.sql` are present.
    ![mart_models](Images/mart_models.png?v=2)
    - **`models/schema.yml`** — Documents the models and defines data-quality tests that dbt will run, such as uniqueness and non-null checks.
    ![schema_yaml](Images/schema_yml.png?v=2)

Together, these files define the flow from the raw Warehouse tables, through cleaned staging models, to the dimension and fact tables used for analytics.

5. To save uploaded changes, click save or "revert" button to discard and redo this exercise.

    ![Save or revert dbt project changes](Images/save-revert.png?v=2)

7. You can either save changes with issues or validate first and save later.
    ![Confirm dbt project validation succeeds](Images/validation_no_issues.png?v=2)
**Success:** Source, staging, mart, and test files are visible.
## Exercise 9: Run models & tests

**Context:** The dbt `build` command executes models in dependency order and then runs the tests associated with them. You will use it to transform the seed data into staging and mart tables, confirm that the project succeeds, and inspect the generated SQL and lineage.

Run or build the staging models, followed by the mart models. If supported:

> **Expected duration:** The first build may take approximately four minutes. Keep the dbt Job page open while it runs, and refresh the status in the results pane if needed.

1. Make sure the dbt command in ribbon is build.

    ![Select the dbt build command](Images/command_build.png?v=2)
2. Click Run to build staging + mart models and run data tests configured.
3. You can see the status of run in the results pane. You can click on refresh to get the latest status of the dbt build.
    ![Monitor a dbt build in progress](Images/run_status_in_progress.png?v=2)
4. Upon completion you can verify the output, compiled sql for selected model or lineage view.
    ![Review the completed dbt build](Images/run_status_completed.png?v=2)

    ![Inspect compiled SQL for a dbt model](Images/compiled_sql.png?v=2)

    ![View dbt model lineage](Images/lineage.png?v=2)
**Success:** All six models complete successfully.

## Exercise 10: Run selected models

**Context:** During development, you often need to run or test one model instead of rebuilding the entire project. You will practice targeting a specific mart model from the editor and using advanced settings to control which dbt resources and commands are executed.

1. You can run selected models manually from the editor. Open the mart model `dim_customer`, and then choose **Run**, **Compile**, **Test**, or **Build** based on the development action you want to perform. In this example, run the data tests to verify the model's data quality.

    ![Run tests for a selected dbt model](Images/selected_test_execution.png?v=2)

2. Open `models/marts/fct_sales.sql` and inspect how the model is built. Identify:

    - `stg_orders` as the source of order transactions.
    - `dim_customer` and `dim_product` as the joined dimension models.
    - `quantity * unit_price` as the calculation used to create `sales_amount`.

    ![Run tests for a selected dbt model](Images/fact_sales.png?v=2)

3. Select **Advanced settings** in the ribbon. Choose only `fct_sales`, and then select **Apply**. Advanced settings can target one or multiple models, while running from the editor targets the model you currently have open.

    > **Note:** If the **Run**, **Compile**, **Test**, and **Build** commands are disabled, open **Advanced settings**, select `fct_sales`, and select **Apply**. The commands should then become available.

    ![Configure advanced dbt run settings](Images/run_advanced_settings.png?v=2)

4. Click on **Test**, in `fct_sales` model. This runs the data-quality tests defined for `fct_sales` without rebuilding the entire project. Conceptually, this is equivalent to:

    ```bash
    dbt test --select fct_sales
    ```

5. Review the results and confirm that both tests on `order_id` pass:

    - `order_id` contains no null values.
    - Every `order_id` value is unique.
![Fact Sales tests](Images/fact_sales_test.png?v=2)
6. Optionally, keep `fct_sales` selected and choose **Run** to execute only that model. This is conceptually equivalent to:

    ```bash
    dbt run --select fct_sales
    ```
    ![Run Fact Sales](Images/run_fact_sales.png?v=2)
**Run** materializes the selected model, **Test** runs its configured data-quality tests, and **Build** runs models and their associated tests.

**Success:** The results show the selected `fct_sales` operation, and its `not_null` and `unique` tests complete successfully.

## Exercise 11: Schedule the dbt Job

**Context:** Production transformations usually run automatically after source data is refreshed. You will create a schedule for the dbt Job and review notification options so that recurring transformations can run without manual intervention and failures can be surfaced.

1. Click on Schedule in Ribbon. 
2. You can add a schedule and configure failure notifications as needed.
    ![Open the dbt job schedule pane](Images/schedule_pane.png?v=2)
3. Configure and Save schedule
    ![Configure a dbt job schedule](Images/configure_schedule.png?v=2)

    ![View configured dbt job schedules](Images/schedules.png?v=2)

**Success:** An enabled schedule is visible.

## Exercise 12: Verify transformed data

**Context:** A successful dbt run indicates that execution completed, but you should also verify the resulting business data. You will query the mart tables in the Warehouse and confirm that the fact model contains the expected joins and calculated sales values.

1. Open Warehouse from `sales_dbt_job` item.
2. Copy paste [`sql/03_verify_marts.sql`](sql/03_verify_marts.sql) file and run the script in the Warehouse.
![Verify transformed warehouse data](Images/verify_data.png?v=2)

3. Complete this guided walkthrough to follow one order from the raw source through the dbt transformation layers.

    **Understand the lineage**

    ```text
    seed.orders ────────> jaffle_shop_staging.stg_orders ───────┐
                                                                │
    seed.customers ─────> jaffle_shop_staging.stg_customers      │
                           └─> jaffle_shop_dbo.dim_customer ──────┼─> jaffle_shop_dbo.fct_sales
                                                                │
    seed.products ──────> jaffle_shop_staging.stg_products       │
                           └─> jaffle_shop_dbo.dim_product ───────┘
    ```

    - The `seed` tables contain the raw source data loaded earlier in the lab.
    - The staging views standardize data types and clean source values.
    - The dimension tables provide descriptive customer and product attributes.
    - `fct_sales` joins orders to those dimensions and calculates `sales_amount`.
    - In Exercise 13, the dimension and fact tables become the source for the semantic model.

    **Inspect the raw order**

    Run this query for order `1002`:

    ```sql
    SELECT
        order_id,
        order_date,
        customer_id,
        product_id,
        quantity
    FROM seed.orders
    WHERE order_id = 1002;
    ```

    Notice that the raw order contains IDs and quantity, but it does not contain customer name, product name, category, price, or sales amount.

    **Inspect the staging model**

    ```sql
    SELECT
        order_id,
        order_date,
        customer_id,
        product_id,
        quantity
    FROM jaffle_shop_staging.stg_orders
    WHERE order_id = 1002;
    ```

    The staging model retains the order grain while standardizing the source columns. The related customer and product staging models also trim text values and convert `unit_price` to a consistent decimal type.

    **Compare the transformed fact row**

    ```sql
    SELECT
        order_id,
        order_date,
        customer_id,
        customer_name,
        segment,
        country,
        product_id,
        product_name,
        category,
        quantity,
        unit_price,
        sales_amount
    FROM jaffle_shop_dbo.fct_sales
    WHERE order_id = 1002;
    ```

    Compare this result with the raw order. dbt has added the customer and product descriptions, the unit price, and the calculated sales amount. For order `1002`, confirm that the result shows `Contoso Retail`, `All-Terrain Bike`, quantity `1`, unit price `1200.00`, and sales amount `1200.00`.

    **Verify the calculation**

    ```sql
    SELECT
        order_id,
        quantity,
        unit_price,
        sales_amount,
        quantity * unit_price AS recalculated_sales_amount
    FROM jaffle_shop_dbo.fct_sales
    ORDER BY order_id;
    ```

    Confirm that `sales_amount` equals `quantity * unit_price` for every order.

**Success:** You traced an order from `seed.orders` through the staging layer to `fct_sales`, verified the added business attributes, and confirmed the `sales_amount` calculation.

## Exercise 13: Create a semantic model

**Context:** The dbt mart tables are optimized for analytics, but report authors need a governed business layer for building Power BI reports. You will create a **Direct Lake on OneLake** semantic model, relate the customer and product dimensions to the sales fact table, and define a reusable `Total Sales` measure. You will then use the model to answer a business question: **How much total sales did each product generate, and how do those results change when filtered to a specific customer?**

1. In the Warehouse, select **New semantic model**.

    ![Create a new semantic model](Images/new_semantic_model.png?v=2)

2. Enter `sales_semantic_model` as the semantic model name and choose **Direct Lake on OneLake** as the storage mode. From the `jaffle_shop_dbo` schema, select:

    - `dim_customer`
    - `dim_product`
    - `fct_sales`

    Confirm your selections and create the semantic model.

    ![Configure the Direct Lake on OneLake semantic model](Images/create_semantic_model.png?v=2)

    > **Expected duration:** Creating the semantic model can take one or two minutes. Wait for the operation to finish; the new semantic model should open automatically.

3. In the model view, confirm that all three tables are present.

    ![View the created semantic model](Images/created_semantic_model.png?v=2)

4. Create the relationships in the semantic model:

    1. On the `dim_customer` table, select the ellipsis (**...**), and then select **Manage relationships**.

        ![Open relationship management for dim_customer](Images/manage_relationship_dim_customer.png?v=2)

    2. Select **New relationship**.

        ![Create a new semantic model relationship](Images/new_relationship.png?v=2)

    3. Configure the customer relationship:

        - Select `dim_customer` and its `customer_id` column.
        - Select `fct_sales` and its `customer_id` column.
        - Choose **One to many (1:*)** cardinality.
        - Save the relationship.

        ![Configure the dim_customer to fct_sales relationship](Images/dim_customer_relationship.png?v=2)

    4. Repeat the process as an exercise by creating a relationship from `dim_product[product_id]` to `fct_sales[product_id]`. Use **One to many (1:*)** cardinality.

    5. Confirm that the model view shows both relationships:

        ![Completed semantic model relationships](Images/relationships.png?v=2)

        ![View active semantic model relationships](Images/visible_relationships.png?v=2)

    Your completed relationships should match the following table:

    | From table and column | Cardinality | To table and column |
    |---|---|---|
    | `dim_customer[customer_id]` | One-to-many (`1:*`) | `fct_sales[customer_id]` |
    | `dim_product[product_id]` | One-to-many (`1:*`) | `fct_sales[product_id]` |

    The dimension tables should be on the `1` side, `fct_sales` should be on the `*` side, and filtering should flow from each dimension to the fact table.


5. Create a reusable measure for calculating total sales:

    1. In the **Data** pane on the right, expand the `fct_sales` table.
    2. Right-click `fct_sales`, and then select **New measure**.

        ![Create a new measure in fct_sales](Images/new_measure.png?v=2)

    3. Enter the following DAX expression in the formula bar, and then select **Commit**:

        ```dax
        Total Sales = SUM(fct_sales[sales_amount])
        ```

        ![Enter the Total Sales measure expression](Images/create_measure.png?v=2)

    4. Confirm that `Total Sales` appears under the `fct_sales` table. In the **Properties** pane, format the measure as currency.

        ![Format the Total Sales measure as currency](Images/format.png?v=2)

    The measure provides a governed, reusable calculation instead of requiring every report author to recreate the sum of `sales_amount`.

6. Use **Explore this data** to analyze total sales by product:

    1. Select **Explore this data** in the ribbon.
    2. Add `dim_product[product_name]` to the visual.
    3. Add the `Total Sales` measure from `fct_sales`.
    4. Open the filter pane and add `dim_customer[customer_name]` as a filter.
    5. Select a customer and confirm that the total sales by product changes to show only that customer's purchases.
    6. Clear the customer filter and confirm that the visual returns to total sales across all customers.

    ![Analyze total sales by product with customer filtering](Images/explored_data.png?v=2)
    7. Optional: select **Save** to retain the exploration.

    ![Save the data exploration](Images/save_exploration.png?v=2)

    The saved exploration will appear as an item in the workspace.

**Success:** The semantic model contains three related tables and a reusable `Total Sales` measure. The visual shows total sales by product and responds correctly when a customer filter is applied or cleared.

## Troubleshooting
- Missing prepared item: contact the instructor; do not use another participant's workspace.
- Wrong target: select `sales_warehouse` in the workspace matching the user suffix.
- Import issue: keep `dbt_project.yml` at the project root.
- Model not found: check filenames and `ref()` values exactly.
