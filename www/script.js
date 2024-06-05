document.addEventListener('DOMContentLoaded', () => {
  const option1 = document.getElementById('item1');
  const option2 = document.getElementById('item2');
  const option3 = document.getElementById('item3');

  const content1 = document.getElementById('tela1');
  const content2 = document.getElementById('tela2');
  const content3 = document.getElementById('tela3');

  function showContent(content) {
    content1.style.display = 'none';
    content2.style.display = 'none';
    content3.style.display = 'none';
    content.style.display = 'block';
  }
  
  option1.addEventListener('click', (e) => {
    e.preventDefault();
    Shiny.setInputValue('map_click_event', new Date().getTime());
    showContent(content1);
  });

  option2.addEventListener('click', (e) => {
    e.preventDefault();
    showContent(content2);
  });

  option3.addEventListener('click', (e) => {
    e.preventDefault();
    showContent(content3);
  });

  

  // Show first tab content by default
  showContent(content1);
});

Shiny.addCustomMessageHandler("dataMessage", function (df) {
  var parentDiv = document.getElementById("estacao_plot");
  var childDivs = parentDiv.getElementsByClassName("apexcharts-canvas");

  var options = {
    series: [{
      name: 'Precipitacao',
      data: df.dados
    }],
    chart: {
      type: 'area',
      stacked: false,
      width: 800,
      height: 350,
      stroke: {
        curve: 'smooth',
      },
      zoom: {
        type: 'x',
        enabled: false,
        autoScaleYaxis: true
      }
    },
    dataLabels: {
      enabled: false
    },
    markers: {
      size: 0,
    },
    title: {
      text: 'Precipitação medida na ' + df.estacao,
      align: 'left'
    },
    fill: {
      type: 'gradient',
    },
    yaxis: {
      title: {
        text: 'Precipitação',
        rotate: -90
      }
    },
    xaxis: {
      type: 'datetime',
    }
  };
  if (childDivs.length == 1) {
    parentDiv.removeChild(childDivs[0]);
  }
  var chart = new ApexCharts(document.querySelector("#estacao_plot"), options);
  chart.render();
});

Shiny.addCustomMessageHandler("data_manaus", function (df) {
  var parentDiv = document.getElementById("manaus_plot");
  var childDivs = parentDiv.getElementsByClassName("apexcharts-canvas");

  var options = {
    series: [{
      name: 'Precipitacao',
      data: df.dados
    }],
    chart: {
      type: 'area',
      stacked: false,
      width: 800,
      height: 350,
      stroke: {
        curve: 'smooth',
      },
      zoom: {
        type: 'x',
        enabled: false,
        autoScaleYaxis: true
      }
    },
    dataLabels: {
      enabled: false
    },
    markers: {
      size: 0,
    },
    title: {
      text: 'Precipitação Media Estimada na cidade de Manaus',
      align: 'left'
    },
    fill: {
      type: 'gradient',
    },
    yaxis: {
      title: {
        text: 'Precipitação',
        rotate: -90
      }
    },
    xaxis: {
      type: 'datetime',
    }
  };
  if (childDivs.length == 1) {
    parentDiv.removeChild(childDivs[0]);
  }
  var chart = new ApexCharts(document.querySelector("#manaus_plot"), options);
  chart.render();
});
