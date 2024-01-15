<script>
  import { Configuration, DefaultApi } from "../api";
  import { onMount } from "svelte";

  let test = "this is a test";

  onMount(async () => {
    console.log("onMount");

    const config = new Configuration({
      basePath: "http://localhost:5800",
    });

    const api = new DefaultApi(config);

    test = await api.
  });
</script>

<svelte:head>
  <title>Home</title>
  <meta name="description" content="Svelte demo app" />
</svelte:head>

<section>
  <h1>
    {test}
  </h1>
</section>

<style>
  section {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    flex: 0.6;
  }

  h1 {
    width: 100%;
  }
</style>
